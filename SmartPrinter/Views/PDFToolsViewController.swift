// PDFToolsViewController.swift
// Full UIViewController + WKWebView integration for Smart PDF Tools.
// Uses WKURLSchemeHandler so Next.js absolute paths (/_next/...) resolve correctly.

import UIKit
import WebKit
import UniformTypeIdentifiers
import VisionKit

// MARK: - Custom URL Scheme Handler
// Serves files from the bundled www/ folder under the smartpdf:// scheme.
// This lets the Next.js build use absolute paths like /_next/static/... without breaking.

private class SmartPDFSchemeHandler: NSObject, WKURLSchemeHandler {

    let wwwURL: URL

    weak var viewController: PDFToolsViewController?

    init(wwwURL: URL) { self.wwwURL = wwwURL }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let requestURL = task.request.url else {
            task.didFailWithError(URLError(.badURL)); return
        }

        // Map URL path → file in the www/ folder
        var path = requestURL.path          // e.g. "/_next/static/css/x.css"
        if path.isEmpty || path == "/" { path = "/index.html" }

        // Support directory paths: /en/tools/merge-pdf → /en/tools/merge-pdf/index.html
        var fileURL = wwwURL.appendingPathComponent(String(path.dropFirst()))
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
            fileURL = fileURL.appendingPathComponent("index.html")
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            NSLog("[NET ❌] \(requestURL.path) → \(fileURL.path)")
            let ext = (requestURL.pathExtension).lowercased()
            let isAsset = ["js", "css", "wasm", "mjs", "json", "woff", "woff2", "ttf", "png", "jpg", "svg", "ico"].contains(ext)
            if isAsset {
                // Return empty JS stub for missing scripts (avoids HTML-as-JS crash in Workers)
                let stub: Data = ext == "css" ? Data() : "/* not found */".data(using: .utf8)!
                let mime = ext == "css" ? "text/css" : "application/javascript"
                let resp = HTTPURLResponse(url: requestURL, statusCode: 404,
                                           httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": mime])!
                task.didReceive(resp)
                task.didReceive(stub)
                task.didFinish()
            } else {
                // SPA fallback: HTML routes handled client-side
                let fallback = wwwURL.appendingPathComponent("index.html")
                if let fallbackData = try? Data(contentsOf: fallback) {
                    NSLog("[NET 🔀] \(requestURL.path) → /index.html (SPA fallback)")
                    let resp = HTTPURLResponse(url: requestURL, statusCode: 200,
                                               httpVersion: "HTTP/1.1",
                                               headerFields: ["Content-Type": "text/html; charset=utf-8",
                                                              "Cross-Origin-Opener-Policy": "same-origin",
                                                              "Cross-Origin-Embedder-Policy": "require-corp"])!
                    task.didReceive(resp)
                    task.didReceive(fallbackData)
                    task.didFinish()
                } else {
                    task.didFailWithError(URLError(.fileDoesNotExist))
                }
            }
            return
        }

        NSLog("[NET ✅] \(requestURL.path) (\(data.count) bytes)")

        let mime = Self.mimeType(for: fileURL.pathExtension)
        var headers: [String: String] = [
            "Content-Type": mime,
            "Content-Length": "\(data.count)",
            // Required headers for SharedArrayBuffer / WASM threads
            "Cross-Origin-Opener-Policy": "same-origin",
            "Cross-Origin-Embedder-Policy": "require-corp",
            "Cross-Origin-Resource-Policy": "cross-origin",
        ]
        // Allow WASM execution
        if mime == "application/wasm" {
            headers["Content-Type"] = "application/wasm"
        }

        let resp = HTTPURLResponse(url: requestURL, statusCode: 200,
                                   httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(resp)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "css":         return "text/css"
        case "js", "mjs":   return "application/javascript"
        case "json":        return "application/json"
        case "wasm":        return "application/wasm"
        case "svg":         return "image/svg+xml"
        case "png":         return "image/png"
        case "jpg","jpeg":  return "image/jpeg"
        case "gif":         return "image/gif"
        case "webp":        return "image/webp"
        case "ico":         return "image/x-icon"
        case "ttf":         return "font/ttf"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        case "otf":         return "font/otf"
        case "mp4":         return "video/mp4"
        case "webmanifest": return "application/manifest+json"
        case "txt":         return "text/plain"
        case "xml":         return "application/xml"
        default:            return "application/octet-stream"
        }
    }
}

// MARK: - PDFToolsViewController

class PDFToolsViewController: UIViewController,
    WKScriptMessageHandler,
    UIDocumentPickerDelegate,
    VNDocumentCameraViewControllerDelegate {

    // MARK: - Properties

    var webView: WKWebView!

    /// Theme set by the SwiftUI wrapper before viewDidLoad.
    var appTheme: AppTheme = .system

    /// Called when the user finishes with the tool and wants to dismiss.
    var onDismiss: (() -> Void)?

    /// Called when the user taps Print — opens native print sheet and saves to history.
    var onPrintFile: ((URL) -> Void)?

    /// Called when the user opens a file to process. Return false to deny (paywall shown by caller).
    var onToolUsed: (() -> Bool)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = appTheme.uiStyle
        view.backgroundColor = .appBackground
        setupNavigationBar()
        setupWebView()
        loadSmartPDF()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        view.backgroundColor = .appBackground
        webView?.backgroundColor = .appBackground
        injectThemeIntoWebView()
    }

    /// Called from PDFToolsView.updateUIViewController when the user changes theme in Settings.
    func applyTheme(_ theme: AppTheme) {
        appTheme = theme
        overrideUserInterfaceStyle = theme.uiStyle
        view.backgroundColor = .appBackground
        webView?.backgroundColor = .appBackground
        injectThemeIntoWebView()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = "PDF Tools"
        navigationController?.navigationBar.tintColor = .appAccent
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.appLabel]
        let homeBtn = UIBarButtonItem(
            title: "Home", style: .plain, target: self, action: #selector(didTapDone)
        )
        homeBtn.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)],
            for: .normal
        )
        navigationItem.rightBarButtonItem = homeBtn
    }

    @objc private func didTapDone() { onDismiss?() }

    // MARK: - WebView Setup

    private func setupWebView() {
        guard let wwwURL = Bundle.main.url(forResource: "www", withExtension: nil) else {
            showErrorPlaceholder(); return
        }

        let config = WKWebViewConfiguration()

        // Register custom scheme handler — fixes Next.js absolute paths under file://
        let schemeHandler = SmartPDFSchemeHandler(wwwURL: wwwURL)
        schemeHandler.viewController = self
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "smartpdf")

        let cc = WKUserContentController()
        ["openFile", "openMultipleFiles", "saveFile", "sharePDF",
         "printPDF", "saveZip", "requestCamera", "toolDone",
         "saveFavorites",
         "_jsLog", "_jsError", "_jsWarn", "_jsInfo"].forEach {
            cc.add(self, name: $0)
        }

        // Inject app theme before any JS runs so app-overrides.js can read it
        let themeScript = WKUserScript(
            source: "window._appTheme = '\(appTheme.jsValue)';",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        cc.addUserScript(themeScript)

        // Seed saved favorites so WKWebView localStorage polyfill can restore them
        let savedFavs = UserDefaults.standard.string(forKey: "smartpdf-favorite-tools") ?? "null"
        let escapedFavs = savedFavs.replacingOccurrences(of: "\\", with: "\\\\")
                                   .replacingOccurrences(of: "'", with: "\\'")
        let favScript = WKUserScript(
            source: "window._spFavData = '\(escapedFavs)';",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        cc.addUserScript(favScript)

        // Inject console bridge — forwards all JS console output to Swift print()
        let consoleBridge = WKUserScript(source: """
            (function() {
                function fwd(level, handler) {
                    var orig = console[level].bind(console);
                    console[level] = function() {
                        var args = Array.prototype.slice.call(arguments);
                        var msg = args.map(function(a) {
                            try { return (typeof a === 'object') ? JSON.stringify(a, null, 2) : String(a); }
                            catch(e) { return String(a); }
                        }).join(' ');
                        try { webkit.messageHandlers[handler].postMessage(msg); } catch(_) {}
                        orig.apply(console, arguments);
                    };
                }
                fwd('log',   '_jsLog');
                fwd('error', '_jsError');
                fwd('warn',  '_jsWarn');
                fwd('info',  '_jsInfo');
                window.addEventListener('error', function(e) {
                    var msg = (e.message || '') + ' @ ' + (e.filename || '') + ':' + e.lineno;
                    try { webkit.messageHandlers._jsError.postMessage('[uncaught] ' + msg); } catch(_) {}
                });
                window.addEventListener('unhandledrejection', function(e) {
                    var msg = e.reason ? (e.reason.stack || String(e.reason)) : 'Unknown promise rejection';
                    try { webkit.messageHandlers._jsError.postMessage('[promise] ' + msg); } catch(_) {}
                });
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false)
        cc.addUserScript(consoleBridge)

        config.userContentController = cc
        config.allowsInlineMediaPlayback = true

        // Required for PyMuPDF WASM
        let prefs = WKPreferences()
        prefs.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences = prefs

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .appBackground
        webView.navigationDelegate = self
        view.addSubview(webView)
    }

    // MARK: - Theme Bridge

    func injectThemeIntoWebView() {
        guard let webView else { return }
        let isDark: Bool
        switch appTheme {
        case .dark:   isDark = true
        case .light:  isDark = false
        case .system: isDark = traitCollection.userInterfaceStyle == .dark
        }
        let js = """
        (function(){
          var h = document.documentElement;
          if (\(isDark ? "true" : "false")) {
            h.classList.add('dark'); h.classList.remove('light');
          } else {
            h.classList.add('light'); h.classList.remove('dark');
          }
          window._appTheme = '\(appTheme.jsValue)';
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - Load Smart PDF

    private func loadSmartPDF() {
        guard let url = URL(string: "smartpdf://localhost/") else { return }
        webView.load(URLRequest(url: url))
    }

    private func showErrorPlaceholder() {
        let label = UILabel()
        label.text = "PDF Tools bundle not found.\nBuild Smart PDF and copy /out → SmartPrinter/PDFTools/www in Xcode."
        label.textColor = UIColor.appLabel.withAlphaComponent(0.5)
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let text = message.body as? String ?? "\(message.body)"
        switch message.name {
        case "_jsLog":   NSLog("[JS]   %@", text)
        case "_jsWarn":  NSLog("[JS ⚠️] %@", text)
        case "_jsError": NSLog("[JS ❌] %@", text)
        case "_jsInfo":  NSLog("[JS ℹ️] %@", text)
        case "openFile":
            if onToolUsed?() ?? true { presentDocumentPicker(multiple: false) }
        case "openMultipleFiles":
            if onToolUsed?() ?? true { presentDocumentPicker(multiple: true) }
        case "saveFile":          handleSave(message.body)
        case "sharePDF":          handleShare(message.body)
        case "printPDF":          handlePrint(message.body)
        case "saveZip":           handleSaveZip(message.body)
        case "requestCamera":     presentDocumentCamera()
        case "toolDone":          break
        case "saveFavorites":
            if text.isEmpty {
                UserDefaults.standard.removeObject(forKey: "smartpdf-favorite-tools")
            } else {
                UserDefaults.standard.set(text, forKey: "smartpdf-favorite-tools")
            }
        default:                  break
        }
    }

    // MARK: - Document Picker

    private func presentDocumentPicker(multiple: Bool) {
        let types: [UTType] = [.pdf, .image, .data,
            UTType("com.microsoft.word.doc"),
            UTType("org.openxmlformats.wordprocessingml.document"),
            UTType("com.microsoft.excel.xls"),
            UTType("org.openxmlformats.spreadsheetml.sheet"),
            UTType("com.microsoft.powerpoint.ppt"),
            UTType("org.openxmlformats.presentationml.presentation")
        ].compactMap { $0 }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = multiple
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if urls.count == 1, let url = urls.first {
            injectSingleFile(url: url)
        } else {
            injectMultipleFiles(urls: urls)
        }
    }

    private func injectSingleFile(url: URL) {
        guard url.startAccessingSecurityScopedResource(),
              let data = try? Data(contentsOf: url) else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let b64  = data.base64EncodedString()
        let name = url.lastPathComponent.replacingOccurrences(of: "'", with: "\\'")
        let js   = "window.receiveFileFromiOS('\(b64)', '\(name)')"
        DispatchQueue.main.async { self.webView.evaluateJavaScript(js, completionHandler: nil) }
    }

    private func injectMultipleFiles(urls: [URL]) {
        var items: [[String: String]] = []
        for url in urls {
            guard url.startAccessingSecurityScopedResource(),
                  let data = try? Data(contentsOf: url) else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            items.append(["data": data.base64EncodedString(), "name": url.lastPathComponent])
        }
        guard !items.isEmpty,
              let json = try? JSONSerialization.data(withJSONObject: items),
              let jsonStr = String(data: json, encoding: .utf8) else { return }
        let js = "window.receiveMultipleFilesFromiOS(\(jsonStr))"
        DispatchQueue.main.async { self.webView.evaluateJavaScript(js, completionHandler: nil) }
    }

    // MARK: - Document Camera

    private func presentDocumentCamera() {
        guard VNDocumentCameraViewController.isSupported else { return }
        let camera = VNDocumentCameraViewController()
        camera.delegate = self
        present(camera, animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)
        var pages: [[String: String]] = []
        for i in 0..<scan.pageCount {
            if let data = scan.imageOfPage(at: i).jpegData(compressionQuality: 0.85) {
                pages.append(["data": data.base64EncodedString(), "name": "scan_page_\(i+1).jpg"])
            }
        }
        guard !pages.isEmpty,
              let json = try? JSONSerialization.data(withJSONObject: pages),
              let jsonStr = String(data: json, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("window.receiveScanFromiOS(\(jsonStr))", completionHandler: nil)
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }

    // MARK: - Save File

    private func handleSave(_ body: Any) {
        guard let dict = body as? [String: Any],
              let b64  = dict["data"] as? String,
              let name = dict["filename"] as? String,
              let data = Data(base64Encoded: b64) else { return }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard (try? data.write(to: tmp)) != nil else { return }

        DispatchQueue.main.async {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            sheet.addAction(UIAlertAction(title: "Save to Files", style: .default) { [weak self] _ in
                self?.present(UIDocumentPickerViewController(forExporting: [tmp], asCopy: true), animated: true)
            })

            sheet.addAction(UIAlertAction(title: "Print", style: .default) { [weak self] _ in
                guard let self = self else { return }
                if let onPrint = self.onPrintFile {
                    onPrint(tmp)
                } else {
                    let info = UIPrintInfo.printInfo()
                    info.outputType = .general
                    info.jobName = name
                    let ctrl = UIPrintInteractionController.shared
                    ctrl.printInfo = info
                    ctrl.printingItem = tmp
                    ctrl.present(animated: true) { [weak self] _, completed, _ in
                        if completed { self?.onPrintFile?(tmp) }
                    }
                }
            })

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let pop = sheet.popoverPresentationController {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 60, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }

            self.present(sheet, animated: true)
        }
    }

    // MARK: - Share PDF

    private func handleShare(_ body: Any) {
        guard let dict = body as? [String: Any],
              let b64  = dict["data"] as? String,
              let name = dict["filename"] as? String,
              let data = Data(base64Encoded: b64) else { return }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard (try? data.write(to: tmp)) != nil else { return }
        DispatchQueue.main.async {
            let activity = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
            if let pop = activity.popoverPresentationController {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            self.present(activity, animated: true)
        }
    }

    // MARK: - Print PDF

    private func handlePrint(_ body: Any) {
        let b64: String
        let jobName: String
        if let str = body as? String {
            b64 = str; jobName = "PrintMate PDF"
        } else if let dict = body as? [String: Any], let s = dict["data"] as? String {
            b64 = s
            jobName = (dict["filename"] as? String) ?? "PrintMate PDF"
        } else { return }
        guard let data = Data(base64Encoded: b64) else { return }

        DispatchQueue.main.async {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(jobName)
            if let onPrint = self.onPrintFile, (try? data.write(to: tmp)) != nil {
                onPrint(tmp)
            } else {
                let info = UIPrintInfo.printInfo()
                info.outputType = .general
                info.jobName = jobName
                let ctrl = UIPrintInteractionController.shared
                ctrl.printInfo = info
                ctrl.printingItem = data
                ctrl.present(animated: true) { [weak self] _, completed, _ in
                    if completed, (try? data.write(to: tmp)) != nil {
                        self?.onPrintFile?(tmp)
                    }
                }
            }
        }
    }

    // MARK: - Scheme Handler Debug

    /// Prints every URL the WebView requests via the custom scheme handler.
    /// Called from SmartPDFSchemeHandler so we can see what files are being fetched.
    fileprivate func logRequest(_ url: URL, hit: Bool) {
        NSLog("[NET \(hit ? "✅" : "❌")] \(url.absoluteString)")
    }

    // MARK: - Save ZIP

    private func handleSaveZip(_ body: Any) {
        guard let dict = body as? [String: Any],
              let b64  = dict["data"] as? String,
              let name = dict["filename"] as? String,
              let data = Data(base64Encoded: b64) else { return }
        let filename = name.hasSuffix(".zip") ? name : name + ".zip"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard (try? data.write(to: tmp)) != nil else { return }
        DispatchQueue.main.async {
            self.present(UIDocumentPickerViewController(forExporting: [tmp], asCopy: true), animated: true)
        }
    }
}

// MARK: - WKNavigationDelegate (navigation + load error logging)

extension PDFToolsViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("[NAV] didStart → \(webView.url?.absoluteString ?? "?")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("[NAV] didFinish → \(webView.url?.absoluteString ?? "?")")
        injectThemeIntoWebView()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("[NAV ❌] didFail: \(error)")
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        NSLog("[NAV ❌] didFailProvisional: \(error)")
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        NSLog("[NAV →] \(action.request.url?.absoluteString ?? "?")")
        decisionHandler(.allow)
    }
}
