import Foundation

/// Persists printers, queue, and history to disk using JSON files in the app's documents directory.
class PersistenceService {

    static let shared = PersistenceService()

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var printersFileURL: URL { documentsURL.appendingPathComponent("printers.json") }
    private var queueFileURL: URL { documentsURL.appendingPathComponent("queue.json") }
    private var historyFileURL: URL { documentsURL.appendingPathComponent("history.json") }
    private var settingsFileURL: URL { documentsURL.appendingPathComponent("settings.json") }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Printers

    func savePrinters(_ printers: [Printer]) {
        save(printers, to: printersFileURL)
    }

    func loadPrinters() -> [Printer] {
        return load(from: printersFileURL) ?? []
    }

    // MARK: - Queue

    func saveQueue(_ jobs: [PrintJob]) {
        save(jobs, to: queueFileURL)
    }

    func loadQueue() -> [PrintJob] {
        return load(from: queueFileURL) ?? []
    }

    // MARK: - History

    func saveHistory(_ jobs: [PrintJob]) {
        save(jobs, to: historyFileURL)
    }

    func loadHistory() -> [PrintJob] {
        return load(from: historyFileURL) ?? []
    }

    // MARK: - Settings

    func saveSettings(_ settings: PrintSettings) {
        save(settings, to: settingsFileURL)
    }

    func loadSettings() -> PrintSettings {
        return load(from: settingsFileURL) ?? PrintSettings()
    }

    // MARK: - Generic

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("PersistenceService save error: \(error)")
        }
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("PersistenceService load error: \(error)")
            return nil
        }
    }
}

struct PrintSettings: Codable {
    var copies: Int = 1
    var paperSize: String = "A4 (210×297mm)"
    var orientation: String = "Portrait"
    var pagesPerSheet: Int = 1
    var colorMode: String = "Color"
    var printQuality: String = "Normal"
    var duplexEnabled: Bool = false
    var collateEnabled: Bool = true
    var printInBackground: Bool = true
    var notificationsEnabled: Bool = true
    var autoReconnect: Bool = true
    var saveHistory: Bool = true
}
