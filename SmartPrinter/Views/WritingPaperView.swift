import SwiftUI
import WebKit

struct WritingPaperView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            WritingPaperWebViewRepresentable(vm: vm, theme: themeManager.current)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Writing Paper")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(.accent)
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
}

struct WritingPaperWebViewRepresentable: UIViewRepresentable {
    let vm: AppViewModel
    let theme: AppTheme

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()

        // Inject theme before page loads
        let themeScript = WKUserScript(
            source: "window._appTheme = '\(theme.jsValue)';",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(themeScript)
        contentController.add(context.coordinator, name: "printPaper")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .appBackground
        webView.overrideUserInterfaceStyle = theme.uiStyle

        if let htmlURL = Bundle.main.url(forResource: "writing_paper", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.overrideUserInterfaceStyle = theme.uiStyle
        // Re-inject theme on live theme change
        let isDark: Bool
        switch theme {
        case .dark:   isDark = true
        case .light:  isDark = false
        case .system: isDark = UITraitCollection.current.userInterfaceStyle == .dark
        }
        let js = """
        (function(){
          var h = document.documentElement;
          if (\(isDark ? "true" : "false")) {
            h.classList.add('dark'); h.classList.remove('light');
          } else {
            h.classList.add('light'); h.classList.remove('dark');
          }
          window._appTheme = '\(theme.jsValue)';
        })();
        """
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKScriptMessageHandler {
        let vm: AppViewModel
        init(vm: AppViewModel) { self.vm = vm }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            NSLog("[WritingPaper] ── printPaper message received ──")
            guard message.name == "printPaper",
                  let base64 = message.body as? String,
                  let data = Data(base64Encoded: base64) else {
                NSLog("[WritingPaper]   ❌ Invalid message format")
                return
            }
            NSLog("[WritingPaper]   decoded data: %d bytes", data.count)

            DispatchQueue.main.async {
                let fileName = "writing_paper_\(UUID().uuidString).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: tempURL)
                    NSLog("[WritingPaper]   ✅ Saved to: %@", tempURL.path)
                    self.vm.printDirectly(url: tempURL, source: "Writing Paper")
                    self.vm.recordActionAndMaybeRate()
                } catch {
                    NSLog("[WritingPaper]   ❌ Write failed: %@", error.localizedDescription)
                    self.vm.showToastMessage("Failed to prepare PDF for printing")
                }
            }
        }
    }
}
