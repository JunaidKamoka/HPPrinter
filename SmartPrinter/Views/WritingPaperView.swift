import SwiftUI
import WebKit

struct WritingPaperView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            WritingPaperWebViewRepresentable(vm: vm)
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

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "printPaper")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false

        if let htmlURL = Bundle.main.url(forResource: "writing_paper", withExtension: "html") {
            // allowingReadAccessTo the same folder so the WebView can read the local file
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKScriptMessageHandler {
        let vm: AppViewModel
        init(vm: AppViewModel) { self.vm = vm }

        /// Called when JS sends: window.webkit.messageHandlers.printPaper.postMessage(base64String)
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "printPaper",
                  let base64 = message.body as? String,
                  let data = Data(base64Encoded: base64) else { return }

            DispatchQueue.main.async {
                let fileName = "writing_paper_\(UUID().uuidString).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: tempURL)
                    self.vm.printDirectly(url: tempURL)
                } catch {
                    self.vm.showToastMessage("Failed to prepare PDF for printing")
                }
            }
        }
    }
}
