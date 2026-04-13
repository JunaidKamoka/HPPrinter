import SwiftUI
import StoreKit
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
    /// Does NOT consume a try — call `consumeFreeTry()` only after the action succeeds.
    /// Shows the paywall when tries are exhausted.
    /// This is the SINGLE gate for ALL paid actions across the entire app:
    /// printing, PDF tools, forms, printables, writing paper — everything.
    @MainActor @discardableResult
    func checkAccess() -> Bool {
        NSLog("[Access] ── checkAccess() ──")
        NSLog("[Access]   isPremium: %@", SubscriptionService.shared.isPremium ? "YES" : "NO")
        NSLog("[Access]   freePrintsUsed: %d / %d", freePrintsUsed, Self.freeTriesLimit)
        NSLog("[Access]   freePrintsRemaining: %d", freePrintsRemaining)
        if SubscriptionService.shared.isPremium {
            NSLog("[Access]   ✅ Premium user — access granted")
            return true
        }
        if freePrintsUsed < Self.freeTriesLimit {
            NSLog("[Access]   ✅ Free tries available (%d remaining) — access granted (not consumed yet)", freePrintsRemaining)
            return true
        }
        NSLog("[Access]   ❌ No free tries left — showing paywall")
        showPaywall = true
        return false
    }

    /// Consume one free try. Call ONLY after the action actually succeeds.
    /// Premium users are not affected.
    @MainActor func consumeFreeTry() {
        if SubscriptionService.shared.isPremium { return }
        if freePrintsUsed < Self.freeTriesLimit {
            freePrintsUsed += 1
            NSLog("[Access] 🔥 Free try CONSUMED → now %d/%d used (%d remaining)", freePrintsUsed, Self.freeTriesLimit, freePrintsRemaining)
        }
    }

    /// Alias kept for backward compatibility — routes to the single checkAccess().
    @MainActor @discardableResult
    func checkTemplateAccess() -> Bool {
        NSLog("[Access] checkTemplateAccess() → forwarding to checkAccess()")
        return checkAccess()
    }

    // MARK: - Rating
    @Published var showRating: Bool = false

    /// Call after any successful user action to record it and maybe show the native rating prompt.
    func recordActionAndMaybeRate() {
        RatingService.shared.recordAction()
        NSLog("[Rating] recordActionAndMaybeRate — shouldShowAfterAction: %@", RatingService.shared.shouldShowAfterAction() ? "YES" : "NO")
        if RatingService.shared.shouldShowAfterAction() {
            RatingService.shared.recordPromptShown()
            NSLog("[Rating]   → showing native rating prompt after 1s delay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestNativeReview()
            }
        }
    }

    private func requestNativeReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
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
        recordActionAndMaybeRate()
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
        NSLog("[Flow] ── handlePickedFile ──")
        NSLog("[Flow]   file: %@", url.lastPathComponent)
        NSLog("[Flow]   ext:  %@", url.pathExtension.lowercased())
        NSLog("[Flow]   path: %@", url.path)
        NSLog("[Flow]   exists: %@", FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")
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
    /// Access is gated — costs 1 free try if not premium.
    func printFile(url: URL, source: String = "Documents") {
        NSLog("[Flow] ══════════════════════════════════")
        NSLog("[Flow] ── printFile() CALLED ──")
        NSLog("[Flow]   source:  %@", source)
        NSLog("[Flow]   file:    %@", url.lastPathComponent)
        NSLog("[Flow]   ext:     %@", url.pathExtension.lowercased())
        NSLog("[Flow]   path:    %@", url.path)
        NSLog("[Flow]   exists:  %@", FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")
        NSLog("[Flow]   printer: %@", primaryPrinter?.name ?? "NONE")
        NSLog("[Flow]   freeTriesRemaining: %d", freePrintsRemaining)

        // ── Access gate: 3 free tries, then paywall ──
        let allowed = MainActor.assumeIsolated { checkAccess() }
        guard allowed else {
            NSLog("[Flow]   ❌ ABORT — access denied, paywall shown")
            return
        }

        guard PrintService.canPrint(url) else {
            NSLog("[Flow]   ❌ ABORT — unsupported file format")
            showToastMessage("Unsupported file format")
            return
        }
        NSLog("[Flow]   ✅ canPrint passed — presenting print sheet...")

        PrintService.presentPrintSheet(url: url) { [weak self] completed, pageCount in
            guard let self else {
                NSLog("[Flow]   ⚠️ self is nil in completion")
                return
            }
            DispatchQueue.main.async {
                NSLog("[Flow] ── printFile COMPLETION ──")
                NSLog("[Flow]   completed: %@", completed ? "YES" : "NO")
                NSLog("[Flow]   pageCount: %d", pageCount)

                guard completed else {
                    NSLog("[Flow]   ❌ User CANCELLED print — free try NOT consumed")
                    self.showToastMessage("Print cancelled")
                    return
                }
                NSLog("[Flow]   ✅ User CONFIRMED print — consuming try & logging to history")
                self.consumeFreeTry()
                self.logHistory(
                    fileName: url.lastPathComponent,
                    fileType: url.pathExtension.lowercased(),
                    pageCount: max(pageCount, 1),
                    source: source,
                    fileURL: url
                )
                self.showToastMessage("Printed: \(url.lastPathComponent)")
                self.recordActionAndMaybeRate()
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
        NSLog("[History] ── logHistory() ──")
        NSLog("[History]   file:   %@", fileName)
        NSLog("[History]   type:   %@", fileType)
        NSLog("[History]   pages:  %d", pageCount)
        NSLog("[History]   source: %@", source)
        NSLog("[History]   status: %@", status == .done ? "done" : "other")
        NSLog("[History]   saveHistory enabled: %@", saveHistory ? "YES" : "NO")
        guard saveHistory else {
            NSLog("[History]   ⚠️ saveHistory is OFF — skipping")
            return
        }
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
        NSLog("[Flow] ── printFromQueue() ──")
        NSLog("[Flow]   job: %@", job.fileName)
        NSLog("[Flow]   hasBookmark: %@", job.fileBookmark != nil ? "YES" : "NO")

        guard let bookmark = job.fileBookmark,
              var isStale = Optional(false),
              let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            NSLog("[Flow]   ❌ ABORT — file bookmark could not be resolved")
            showToastMessage("File no longer available")
            queue.removeAll { $0.id == job.id }
            persistence.saveQueue(queue)
            return
        }
        NSLog("[Flow]   resolved URL: %@", url.path)
        NSLog("[Flow]   isStale: %@", isStale ? "YES" : "NO")

        printFile(url: url, source: "Queue")
        queue.removeAll { $0.id == job.id }
        persistence.saveQueue(queue)
    }

    func printDirectly(url: URL, source: String = "Documents") {
        NSLog("[Flow] ── printDirectly() → forwarding to printFile() ──")
        NSLog("[Flow]   source: %@", source)
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
        NSLog("[Flow] ── reprintFromHistory() ──")
        NSLog("[Flow]   job: %@", job.fileName)
        NSLog("[Flow]   hasBookmark: %@", job.fileBookmark != nil ? "YES" : "NO")

        guard let bookmark = job.fileBookmark,
              var isStale = Optional(false),
              let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
              FileManager.default.fileExists(atPath: url.path) else {
            NSLog("[Flow]   ❌ ABORT — file not available (no bookmark or file missing)")
            showToastMessage("File no longer available — pick it again to print")
            return
        }
        NSLog("[Flow]   resolved URL: %@", url.path)
        printFile(url: url, source: "Reprint")
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
        NSLog("[Flow] ══════════════════════════════════")
        NSLog("[Flow] ── sendTestPrint() ──")
        NSLog("[Flow]   name: %@", testPrint.name)
        NSLog("[Flow]   file: %@", testPrint.fileName)
        NSLog("[Flow]   url:  %@", testPrint.remoteURL)

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("TestPrints", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let localURL = cacheDir.appendingPathComponent(testPrint.fileName)

        // Use cached file if available
        if FileManager.default.fileExists(atPath: localURL.path) {
            NSLog("[Flow]   ✅ Cached file found — printing directly")
            printFile(url: localURL, source: "Test Print")
            return
        }

        // Download then print
        guard let url = URL(string: testPrint.remoteURL) else {
            NSLog("[Flow]   ❌ ABORT — invalid remote URL")
            return
        }
        isDownloadingTestPrint = true
        NSLog("[Flow]   ⏳ Downloading from remote...")
        showToastMessage("Downloading \(testPrint.name)...")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isDownloadingTestPrint = false

                if let error = error {
                    NSLog("[Flow]   ❌ Download error: %@", error.localizedDescription)
                }

                guard let data = data, error == nil, !data.isEmpty else {
                    NSLog("[Flow]   ❌ Download failed — no data or error")
                    self?.showToastMessage("Download failed — check internet connection")
                    return
                }

                NSLog("[Flow]   Downloaded %d bytes", data.count)

                // Verify we got a valid response (not an error page)
                if let httpResponse = response as? HTTPURLResponse {
                    NSLog("[Flow]   HTTP status: %d", httpResponse.statusCode)
                    if httpResponse.statusCode != 200 {
                        NSLog("[Flow]   ❌ Download failed — non-200 status")
                        self?.showToastMessage("Download failed (HTTP \(httpResponse.statusCode))")
                        return
                    }
                }

                do {
                    try data.write(to: localURL, options: .atomic)
                    NSLog("[Flow]   ✅ Saved to cache, printing...")
                    self?.printFile(url: localURL, source: "Test Print")
                } catch {
                    NSLog("[Flow]   ⚠️ Cache write failed: %@, using data fallback", error.localizedDescription)
                    // Fallback: print directly from data if file write fails
                    PrintService.presentPrintSheet(data: data, jobName: testPrint.name) { completed in
                        DispatchQueue.main.async {
                            NSLog("[Flow]   Test print (data fallback) completed: %@", completed ? "YES" : "NO")
                            if completed {
                                self?.consumeFreeTry()
                                self?.logHistory(
                                    fileName: testPrint.name,
                                    fileType: "pdf",
                                    pageCount: 1,
                                    source: "Test Print"
                                )
                                self?.recordActionAndMaybeRate()
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
