import Foundation
import Combine

// MARK: - TemplateDataService
//
// Data flow:
//   1. init()         → load from disk cache instantly (no UI wait)
//   2. fetchAndSync() → download from Firebase Storage → parse → update cache
//
// The Views just observe the @Published properties — they update automatically.

final class TemplateDataService: ObservableObject {

    static let shared = TemplateDataService()

    // MARK: - Published state
    @Published var formsByCountry: [String: [FormItem]]  = [:]
    @Published var categories:     [PrintableCategory]   = []
    @Published var isLoading:       Bool                 = true   // true until first data arrives
    @Published var loadError:       String?              = nil
    @Published var isSyncing:       Bool                 = false  // background Firebase refresh
    @Published var syncMessage:     String               = "Preparing…"
    @Published var lastSyncDate:    Date?                = nil

    // MARK: - Cache paths (disk)
    private static let cacheDir: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }()
    private static var formsCachePath:      URL { cacheDir.appendingPathComponent("hp_forms_v3.json") }
    private static var printablesCachePath: URL { cacheDir.appendingPathComponent("hp_printables_v3.json") }
    private static let kLastSync = "hp_templates_last_sync_v3"

    // MARK: - Firebase download URLs
    private var formsDownloadURL: URL? {
        let bucket = FirebaseConfig.storageBucket
        guard !bucket.isEmpty else { return nil }
        return URL(string:
            "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/" +
            "templates%2Ffirebase_forms.json?alt=media"
        )
    }
    private var printablesDownloadURL: URL? {
        let bucket = FirebaseConfig.storageBucket
        guard !bucket.isEmpty else { return nil }
        return URL(string:
            "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/" +
            "templates%2Ffirebase_printables.json?alt=media"
        )
    }

    // MARK: - Init

    private init() {
        lastSyncDate = UserDefaults.standard.object(forKey: Self.kLastSync) as? Date
        loadFromCache()
    }

    // MARK: - Public helpers (unchanged API — FormsView/PrintablesView work as-is)

    var allCountries: [String] { formsByCountry.keys.sorted() }

    func forms(for country: String, search: String = "") -> [FormItem] {
        let base = formsByCountry[country] ?? []
        guard !search.isEmpty else { return base }
        return base.filter { $0.matches(search) }
    }

    func allForms(search: String = "") -> [FormItem] {
        let all = formsByCountry.values.flatMap { $0 }
        if search.isEmpty { return all.sorted { $0.displayTitle < $1.displayTitle } }
        return all.filter { $0.matches(search) }.sorted { $0.displayTitle < $1.displayTitle }
    }

    // Legacy alias — retry button in FormsView calls data.load()
    func load() { fetchAndSync() }

    // MARK: - Step 1: Load from disk cache (instant)

    private func loadFromCache() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let formsData      = Self.readDisk(Self.formsCachePath)
                              ?? Self.readBundle("firebase_forms")
            let printablesData = Self.readDisk(Self.printablesCachePath)
                              ?? Self.readBundle("firebase_printables")

            let forms = formsData.map      { Self.parseForms(from: $0) }      ?? [:]
            let cats  = printablesData.map { Self.parsePrintables(from: $0) } ?? []

            DispatchQueue.main.async {
                self.formsByCountry = forms
                self.categories     = cats
                // If we already have data, stop blocking spinner
                if !forms.isEmpty || !cats.isEmpty {
                    self.isLoading    = false
                    self.syncMessage  = "Loading latest data…"
                } else {
                    self.isLoading    = true
                    self.syncMessage  = "Downloading templates…"
                }
            }
        }
    }

    // MARK: - Step 2: Fetch & Sync from Firebase (called at Splash)

    func fetchAndSync() {
        guard !isSyncing else { return }
        isSyncing  = true
        loadError  = nil
        syncMessage = "Downloading templates…"

        let group = DispatchGroup()
        var formsData:      Data?
        var printablesData: Data?
        var firstError:     String?

        // --- Forms ---
        if let url = formsDownloadURL {
            group.enter()
            fetch(url: url) { data, error in
                formsData = data
                if data == nil { firstError = error }
                group.leave()
            }
        }

        // --- Printables ---
        if let url = printablesDownloadURL {
            group.enter()
            fetch(url: url) { data, error in
                printablesData = data
                if data == nil, firstError == nil { firstError = error }
                group.leave()
            }
        }

        // --- Both done ---
        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            guard let self else { return }

            let newForms = formsData.map      { Self.parseForms(from: $0) }      ?? [:]
            let newCats  = printablesData.map { Self.parsePrintables(from: $0) } ?? []

            // Merge: prefer fresh data; fall back to what was already loaded
            let mergedForms = newForms.isEmpty ? self.formsByCountry : newForms
            let mergedCats  = newCats.isEmpty  ? self.categories     : newCats

            // Persist to cache
            if let d = formsData,      !d.isEmpty { Self.writeDisk(d, to: Self.formsCachePath) }
            if let d = printablesData, !d.isEmpty { Self.writeDisk(d, to: Self.printablesCachePath) }

            let syncDate = (formsData != nil || printablesData != nil) ? Date() : self.lastSyncDate
            if formsData != nil || printablesData != nil {
                UserDefaults.standard.set(syncDate, forKey: Self.kLastSync)
            }

            DispatchQueue.main.async {
                self.formsByCountry = mergedForms
                self.categories     = mergedCats
                self.lastSyncDate   = syncDate
                self.isLoading      = false
                self.isSyncing      = false

                if !mergedForms.isEmpty || !mergedCats.isEmpty {
                    let count = mergedForms.values.flatMap { $0 }.count
                              + mergedCats.reduce(0) { $0 + $1.itemCount }
                    self.syncMessage = formsData != nil
                        ? "✓ \(count) templates ready"
                        : "✓ Ready (cached)"
                    self.loadError = nil
                } else {
                    let msg = firstError ?? "Unable to connect. Check your internet connection."
                    self.loadError  = msg
                    self.syncMessage = "Sync failed"
                }
            }
        }
    }

    // MARK: - Network helper

    private func fetch(url: URL, completion: @escaping (Data?, String?) -> Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data, !data.isEmpty {
                completion(data, nil)
            } else {
                completion(nil, error?.localizedDescription ?? "Empty response")
            }
        }.resume()
    }

    // MARK: - Disk I/O

    private static func readDisk(_ url: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func writeDisk(_ data: Data, to url: URL) {
        try? data.write(to: url, options: .atomic)
    }

    private static func readBundle(_ name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Parsers

    static func parseForms(from data: Data) -> [String: [FormItem]] {
        guard !data.isEmpty,
              let root      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let formsDict = root["forms"] as? [String: Any]
        else { return [:] }

        var result: [String: [FormItem]] = [:]
        let decoder = JSONDecoder()
        for (country, value) in formsDict {
            guard
                let array    = value as? [[String: Any]],
                let jsonData = try? JSONSerialization.data(withJSONObject: array),
                let items    = try? decoder.decode([FormItem].self, from: jsonData)
            else { continue }
            result[country] = items
        }
        return result
    }

    static func parsePrintables(from data: Data) -> [PrintableCategory] {
        guard !data.isEmpty,
              let root           = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let printablesDict = root["printables"] as? [String: Any]
        else { return [] }

        var cats: [PrintableCategory] = []
        let decoder = JSONDecoder()
        for (_, value) in printablesDict {
            guard
                let catJSON = try? JSONSerialization.data(withJSONObject: value),
                let cat     = try? decoder.decode(PrintableCategory.self, from: catJSON)
            else { continue }
            cats.append(cat)
        }
        return cats.sorted { $0.categoryName < $1.categoryName }
    }
}

// MARK: - FormItem Search Helper
private extension FormItem {
    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return displayTitle.lowercased().contains(q)
            || subtitle.lowercased().contains(q)
            || description.lowercased().contains(q)
            || country.lowercased().contains(q)
            || tags.contains { $0.lowercased().contains(q) }
    }
}
