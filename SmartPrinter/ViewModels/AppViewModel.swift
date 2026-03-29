import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    // MARK: - Data
    @Published var savedPrinters: [Printer] = []
    @Published var queue: [PrintJob] = []
    @Published var history: [PrintJob] = []

    // MARK: - Discovery
    @Published var discoveryService = PrinterDiscoveryService()
    private var discoveryCancellable: AnyCancellable?

    // MARK: - Subscription / Paywall
    @Published var showPaywall: Bool = false

    var paywallShowCount: Int {
        get { UserDefaults.standard.integer(forKey: "hp_paywall_show_count") }
        set { UserDefaults.standard.set(newValue, forKey: "hp_paywall_show_count") }
    }

    /// Pure read — no side effects. Call nextPaywallVariant() to advance.
    var paywallVariant: Int { paywallShowCount % 3 }

    func nextPaywallVariant() { paywallShowCount += 1 }

    private let freeTriesKey = "hp_free_tries_used"
    static let freeTriesLimit = 3

    var freePrintsUsed: Int {
        get { UserDefaults.standard.integer(forKey: freeTriesKey) }
        set { UserDefaults.standard.set(newValue, forKey: freeTriesKey); objectWillChange.send() }
    }

    var freePrintsRemaining: Int { max(0, Self.freeTriesLimit - freePrintsUsed) }

    @MainActor var isPremium: Bool { SubscriptionService.shared.isPremium }

    /// Returns true if the action is allowed (premium or has free tries left).
    /// Increments the try counter and shows the paywall when tries are exhausted.
    /// In DEBUG builds all actions are always allowed.
    @MainActor @discardableResult
    func checkAccess() -> Bool {
        #if DEBUG
        return true
        #else
        if SubscriptionService.shared.isPremium { return true }
        if freePrintsUsed < Self.freeTriesLimit {
            freePrintsUsed += 1
            return true
        }
        showPaywall = true
        return false
        #endif
    }

    // MARK: - Template Access (first template is free; rest require premium)

    private let freeTemplateKey = "hp_free_template_used"

    var freeTemplateUsed: Bool {
        get { UserDefaults.standard.bool(forKey: freeTemplateKey) }
        set { UserDefaults.standard.set(newValue, forKey: freeTemplateKey); objectWillChange.send() }
    }

    /// First template print is always free. Subsequent prints require premium.
    @MainActor @discardableResult
    func checkTemplateAccess() -> Bool {
        #if DEBUG
        return true
        #else
        if SubscriptionService.shared.isPremium { return true }
        if !freeTemplateUsed {
            freeTemplateUsed = true
            return true
        }
        showPaywall = true
        return false
        #endif
    }

    // MARK: - UI State
    @Published var toastMessage: String = ""
    @Published var showToast: Bool = false
    @Published var selectedFileURL: URL?

    // MARK: - Settings
    @Published var copies: Int = 1
    @Published var paperSize: String = "A4 (210×297mm)"
    @Published var orientation: String = "Portrait"
    @Published var pagesPerSheet: Int = 1
    @Published var colorMode: String = "Color"
    @Published var printQuality: String = "Normal"
    @Published var duplexEnabled: Bool = false
    @Published var collateEnabled: Bool = true
    @Published var printInBackground: Bool = true
    @Published var notificationsEnabled: Bool = true
    @Published var autoReconnect: Bool = true
    @Published var saveHistory: Bool = true

    // Haptics (backed by HapticService so buttons read it directly)
    var hapticsEnabled: Bool {
        get { HapticService.shared.isEnabled }
        set { HapticService.shared.isEnabled = newValue; objectWillChange.send() }
    }

    private let persistence = PersistenceService.shared

    // MARK: - Computed

    var primaryPrinter: Printer? { savedPrinters.first(where: { $0.isPrimary }) ?? savedPrinters.first }

    var allKnownPrinters: [Printer] {
        var result = savedPrinters
        for discovered in discoveryService.discoveredPrinters {
            if !result.contains(where: { $0.id == discovered.id }) {
                result.append(discovered)
            }
        }
        return result
    }

    var connectedPrinters: [Printer] {
        savedPrinters.filter { $0.status == .online }
    }

    var networkPrinters: [Printer] {
        discoveryService.discoveredPrinters.filter { discovered in
            !savedPrinters.contains(where: { $0.id == discovered.id })
        }
    }

    var totalPagesPrinted: Int {
        history.filter { $0.status == .done }.reduce(0) { $0 + ($1.pageCount * $1.copies) }
    }

    var successRate: Double {
        let done = history.filter { $0.status == .done }.count
        let total = history.count
        return total > 0 ? Double(done) / Double(total) : 0
    }

    var todayJobCount: Int {
        let cal = Calendar.current
        return history.filter { cal.isDateInToday($0.date) && $0.status == .done }.count
    }

    var isScanning: Bool { discoveryService.isSearching }

    // MARK: - Init

    init() {
        loadAll()
        discoveryCancellable = discoveryService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    func loadAll() {
        savedPrinters = persistence.loadPrinters()
        queue = persistence.loadQueue()
        history = persistence.loadHistory()

        let settings = persistence.loadSettings()
        copies = settings.copies
        paperSize = settings.paperSize
        orientation = settings.orientation
        pagesPerSheet = settings.pagesPerSheet
        colorMode = settings.colorMode
        printQuality = settings.printQuality
        duplexEnabled = settings.duplexEnabled
        collateEnabled = settings.collateEnabled
        printInBackground = settings.printInBackground
        notificationsEnabled = settings.notificationsEnabled
        autoReconnect = settings.autoReconnect
        saveHistory = settings.saveHistory
        HapticService.shared.isEnabled = settings.hapticsEnabled
    }

    // MARK: - Toast

    func showToastMessage(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { self.showToast = false }
        }
    }

    // MARK: - Discovery

    func startScan() {
        discoveryService.startSearch()
        showToastMessage("Scanning for printers...")
    }

    func stopScan() {
        discoveryService.stop()
    }

    // MARK: - Printer Management

    func addPrinter(_ printer: Printer) {
        var p = printer
        if savedPrinters.isEmpty { p.isPrimary = true }
        savedPrinters.append(p)
        persistence.savePrinters(savedPrinters)
        showToastMessage("Printer added: \(p.name)")
        logPrinterEvent(event: "Added: \(p.name)", printerName: p.name)
    }

    func removePrinter(_ printer: Printer) {
        logPrinterEvent(event: "Removed: \(printer.name)", printerName: printer.name)
        savedPrinters.removeAll { $0.id == printer.id }
        if printer.isPrimary, let first = savedPrinters.first {
            if let idx = savedPrinters.firstIndex(where: { $0.id == first.id }) {
                savedPrinters[idx].isPrimary = true
            }
        }
        persistence.savePrinters(savedPrinters)
    }

    func setPrimary(_ printer: Printer) {
        for i in savedPrinters.indices {
            savedPrinters[i].isPrimary = (savedPrinters[i].id == printer.id)
        }
        persistence.savePrinters(savedPrinters)
        showToastMessage("\(printer.name) set as primary")
        logPrinterEvent(event: "Set Primary: \(printer.name)", printerName: printer.name)
    }

    private func logPrinterEvent(event: String, printerName: String) {
        guard saveHistory else { return }
        let job = PrintJob(
            fileName: event,
            fileType: "printer",
            pageCount: 0,
            printerName: printerName,
            colorMode: "-",
            duplex: false,
            paperSize: "-",
            copies: 0,
            status: .done,
            progress: 1.0,
            date: Date(),
            source: "Printer"
        )
        history.insert(job, at: 0)
        persistence.saveHistory(history)
    }

    // MARK: - File Handling

    func handlePickedFile(url: URL) {
        selectedFileURL = url
        RatingService.shared.recordAction()
    }

    // MARK: - Queue Management

    func addToQueue(url: URL, printerName: String? = nil) {
        let ext = url.pathExtension.lowercased()
        let pageCount = PrintService.estimatePageCount(for: url)

        let job = PrintJob(
            fileName: url.lastPathComponent,
            fileType: ext,
            pageCount: pageCount,
            printerName: printerName ?? primaryPrinter?.name ?? "No Printer",
            colorMode: colorMode,
            duplex: duplexEnabled,
            paperSize: paperSize,
            copies: copies,
            status: .queued,
            progress: 0,
            date: Date(),
            fileBookmark: try? url.bookmarkData(),
            source: "Queue"
        )
        queue.append(job)
        persistence.saveQueue(queue)
        showToastMessage("Added to queue: \(url.lastPathComponent)")
    }

    func removeFromQueue(_ job: PrintJob) {
        queue.removeAll { $0.id == job.id }
        persistence.saveQueue(queue)
        showToastMessage("Removed from queue")
    }

    func clearQueue() {
        queue.removeAll()
        persistence.saveQueue(queue)
        showToastMessage("Queue cleared")
    }

    // MARK: - Printing (native sheet handles everything)

    /// Opens the native iOS print sheet for any file URL and logs to history on completion.
    func printFile(url: URL, source: String = "Documents") {
        PrintService.presentPrintSheet(url: url) { [weak self] completed, pageCount in
            guard let self else { return }
            DispatchQueue.main.async {
                guard completed else {
                    self.showToastMessage("Print cancelled")
                    return
                }
                self.logHistory(
                    fileName: url.lastPathComponent,
                    fileType: url.pathExtension.lowercased(),
                    pageCount: max(pageCount, 1),
                    source: source,
                    fileURL: url
                )
                self.showToastMessage("Printed: \(url.lastPathComponent)")
            }
        }
    }

    /// Log a completed print job to history directly — call this when the print sheet
    /// was already presented by the caller (Forms, Printables) so we don't open a second sheet.
    func logHistory(
        fileName: String,
        fileType: String,
        pageCount: Int,
        source: String,
        status: JobStatus = .done,
        fileURL: URL? = nil
    ) {
        guard saveHistory else { return }
        let job = PrintJob(
            fileName: fileName,
            fileType: fileType,
            pageCount: pageCount,
            printerName: primaryPrinter?.name ?? "AirPrint",
            colorMode: colorMode,
            duplex: duplexEnabled,
            paperSize: paperSize,
            copies: copies,
            status: status,
            progress: status == .done ? 1.0 : 0,
            date: Date(),
            duration: status == .done ? "Completed" : nil,
            fileBookmark: fileURL.flatMap { try? $0.bookmarkData() },
            source: source
        )
        history.insert(job, at: 0)
        persistence.saveHistory(history)
        RatingService.shared.recordAction()
    }

    func printFromQueue(_ job: PrintJob) {
        guard let bookmark = job.fileBookmark,
              var isStale = Optional(false),
              let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            showToastMessage("File no longer available")
            queue.removeAll { $0.id == job.id }
            persistence.saveQueue(queue)
            return
        }

        printFile(url: url, source: "Queue")
        queue.removeAll { $0.id == job.id }
        persistence.saveQueue(queue)
    }

    func printDirectly(url: URL, source: String = "Documents") {
        printFile(url: url, source: source)
    }

    // MARK: - History

    func clearHistory() {
        history.removeAll()
        persistence.saveHistory(history)
        showToastMessage("History cleared")
    }

    func removeFromHistory(_ job: PrintJob) {
        history.removeAll { $0.id == job.id }
        persistence.saveHistory(history)
        showToastMessage("Removed from history")
    }

    func reprintFromHistory(_ job: PrintJob) {
        guard let bookmark = job.fileBookmark,
              var isStale = Optional(false),
              let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
              FileManager.default.fileExists(atPath: url.path) else {
            showToastMessage("File no longer available — pick it again to print")
            return
        }
        printFile(url: url)
    }

    // MARK: - Settings

    func saveSettings() {
        let settings = PrintSettings(
            copies: copies, paperSize: paperSize, orientation: orientation,
            pagesPerSheet: pagesPerSheet, colorMode: colorMode, printQuality: printQuality,
            duplexEnabled: duplexEnabled, collateEnabled: collateEnabled,
            printInBackground: printInBackground, notificationsEnabled: notificationsEnabled,
            autoReconnect: autoReconnect, saveHistory: saveHistory,
            hapticsEnabled: HapticService.shared.isEnabled
        )
        persistence.saveSettings(settings)
        showToastMessage("Settings saved")
    }

    func resetSettings() {
        let defaults = PrintSettings()
        copies = defaults.copies
        paperSize = defaults.paperSize
        orientation = defaults.orientation
        pagesPerSheet = defaults.pagesPerSheet
        colorMode = defaults.colorMode
        printQuality = defaults.printQuality
        duplexEnabled = defaults.duplexEnabled
        collateEnabled = defaults.collateEnabled
        printInBackground = defaults.printInBackground
        notificationsEnabled = defaults.notificationsEnabled
        autoReconnect = defaults.autoReconnect
        saveHistory = defaults.saveHistory
        HapticService.shared.isEnabled = defaults.hapticsEnabled
        persistence.saveSettings(defaults)
        showToastMessage("Settings reset to defaults")
    }

    // MARK: - Test Prints

    struct TestPrint: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let subtitle: String
        let fileName: String
        let remoteURL: String
    }

    static let testPrints: [TestPrint] = [
        TestPrint(
            name: "Color Vector (Letter)",
            icon: "🌈",
            subtitle: "Color rulers, text & gamut chart",
            fileName: "letter-portrait-vector-color.pdf",
            remoteURL: "https://raw.githubusercontent.com/OpenPrinting/sample-files/main/pdf/letter-portrait-vector-color.pdf"
        ),
        TestPrint(
            name: "B&W Grayscale Photo",
            icon: "📄",
            subtitle: "Grayscale photo, 4×6 landscape",
            fileName: "4x6-landscape-photo-sgray.jpg",
            remoteURL: "https://raw.githubusercontent.com/OpenPrinting/sample-files/main/jpeg/4x6-landscape-photo-sgray.jpg"
        ),
        TestPrint(
            name: "Color Photo (4×6)",
            icon: "🖼️",
            subtitle: "sRGB color photo, portrait",
            fileName: "4x6-portrait-photo-srgb.jpg",
            remoteURL: "https://raw.githubusercontent.com/OpenPrinting/sample-files/main/jpeg/4x6-portrait-photo-srgb.jpg"
        ),
        TestPrint(
            name: "A4 Vector Page",
            icon: "📐",
            subtitle: "A4 color rulers & text alignment",
            fileName: "a4-portrait-vector-color.pdf",
            remoteURL: "https://raw.githubusercontent.com/OpenPrinting/sample-files/main/pdf/a4-portrait-vector-color.pdf"
        ),
        TestPrint(
            name: "Label / Small (A6)",
            icon: "🏷️",
            subtitle: "Small format vector test page",
            fileName: "a6-portrait-vector-color.pdf",
            remoteURL: "https://raw.githubusercontent.com/OpenPrinting/sample-files/main/pdf/a6-portrait-vector-color.pdf"
        )
    ]

    @Published var isDownloadingTestPrint = false

    func sendTestPrint(_ testPrint: TestPrint) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("TestPrints", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let localURL = cacheDir.appendingPathComponent(testPrint.fileName)

        // Use cached file if available
        if FileManager.default.fileExists(atPath: localURL.path) {
            printFile(url: localURL, source: "Test Print")
            return
        }

        // Download then print
        guard let url = URL(string: testPrint.remoteURL) else { return }
        isDownloadingTestPrint = true
        showToastMessage("Downloading \(testPrint.name)...")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isDownloadingTestPrint = false

                guard let data = data, error == nil, !data.isEmpty else {
                    self?.showToastMessage("Download failed — check internet connection")
                    return
                }

                // Verify we got a valid response (not an error page)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self?.showToastMessage("Download failed (HTTP \(httpResponse.statusCode))")
                    return
                }

                do {
                    try data.write(to: localURL, options: .atomic)
                    self?.printFile(url: localURL, source: "Test Print")
                } catch {
                    // Fallback: print directly from data if file write fails
                    PrintService.presentPrintSheet(data: data, jobName: testPrint.name) { completed in
                        DispatchQueue.main.async {
                            if completed {
                                self?.logHistory(
                                    fileName: testPrint.name,
                                    fileType: "pdf",
                                    pageCount: 1,
                                    source: "Test Print"
                                )
                            }
                            self?.showToastMessage(completed ? "\(testPrint.name) sent" : "Print cancelled")
                        }
                    }
                }
            }
        }.resume()
    }

    // Legacy convenience
    func sendTestPage() {
        if let first = Self.testPrints.first {
            sendTestPrint(first)
        }
    }
}
