import SwiftUI
import UIKit
import PDFKit

// MARK: - DocumentReaderView
//
// A responsive, multi-page document reader for both image-based forms and PDF printables.
//
//   DocumentReaderView(mode: .images([URL?]))  → each page shown in its natural aspect ratio
//                                                 with pinch-to-zoom and double-tap support
//   DocumentReaderView(mode: .pdf(URL))         → PDF downloaded and shown with PDFKit
//                                                 (continuous vertical scroll + pinch-to-zoom)
//   DocumentReaderView(mode: .empty)            → friendly empty-state placeholder

struct DocumentReaderView: View {

    enum Mode {
        case images([URL?])
        case pdf(URL)
        case empty
    }

    let mode: Mode
    var cornerRadius: CGFloat = 16

    var body: some View {
        switch mode {
        case .images(let urls):
            ImagePageReader(urls: urls, cornerRadius: cornerRadius)
        case .pdf(let url):
            PDFRemoteReader(url: url, cornerRadius: cornerRadius)
        case .empty:
            emptyPlaceholder
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 44))
                .foregroundColor(.textTertiary.opacity(0.4))
            Text("No preview available")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - ImagePageReader
// All pages stacked vertically; each page self-sizes to its natural aspect ratio
// and can be independently pinch-zoomed or double-tapped.

private struct ImagePageReader: View {
    let urls: [URL?]
    var cornerRadius: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                if let url {
                    ZoomablePageView(url: url)
                } else {
                    unavailablePage(index: index)
                }

                if index < urls.count - 1 {
                    Divider()
                        .background(Color.cardBorder.opacity(0.6))
                }
            }
        }
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }

    private func unavailablePage(index: Int) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(.textTertiary.opacity(0.35))
            Text("Page \(index + 1) unavailable")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(Color.bg3)
    }
}

// MARK: - ZoomablePageView
// SwiftUI wrapper for a single page image.
// Loads via the project's existing ImageLoader (with NSCache), then sizes the
// UIScrollView container to the image's natural aspect ratio so the layout
// reflows correctly rather than using a fixed height.

struct ZoomablePageView: View {
    let url: URL

    @StateObject private var loader = ImageLoader()
    /// height / width ratio — starts at A4 (1.41), updates once image is decoded
    @State private var heightRatio: CGFloat = 1.41

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.width * heightRatio
            ZoomableUIScrollView(image: loader.image)
                .frame(width: geo.size.width, height: height)
                .overlay {
                    if loader.isLoading {
                        ShimmerView()
                    } else if loader.hasFailed || loader.image == nil {
                        failedState
                    }
                }
        }
        // Let SwiftUI give us the right height by using the current ratio
        .aspectRatio(1.0 / heightRatio, contentMode: .fit)
        .onAppear { loader.load(url: url) }
        .onChange(of: loader.image) { image in
            if let img = image, img.size.width > 0 {
                withAnimation(.easeOut(duration: 0.15)) {
                    heightRatio = img.size.height / img.size.width
                }
            }
        }
    }

    private var failedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundColor(.textTertiary.opacity(0.35))
            Text("Preview unavailable")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg3)
    }
}

// MARK: - ZoomableUIScrollView
// UIScrollView with pinch-to-zoom (1×–4×) and double-tap toggle.
// The imageView always fills the scroll view frame at scale 1; zoom
// scales content above that, centered automatically.

struct ZoomableUIScrollView: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> UIScrollView {
        let scroll              = UIScrollView()
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 4.0
        scroll.bouncesZoom      = true
        scroll.showsVerticalScrollIndicator   = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor  = UIColor(Color.bg2)
        scroll.delegate         = context.coordinator

        let iv           = UIImageView()
        iv.tag           = 1
        iv.contentMode   = .scaleAspectFit
        iv.backgroundColor = .clear
        scroll.addSubview(iv)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleDoubleTap(_:)))
        tap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(tap)

        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        guard let iv = scroll.viewWithTag(1) as? UIImageView else { return }

        // Only update if image changed
        if iv.image !== image {
            iv.image = image
            scroll.setZoomScale(1.0, animated: false)
        }

        // Always keep imageView filling the scroll bounds
        if iv.frame.size != scroll.bounds.size {
            iv.frame       = CGRect(origin: .zero, size: scroll.bounds.size)
            scroll.contentSize = scroll.bounds.size
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(1)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            recenterContent(in: scrollView)
        }

        private func recenterContent(in scroll: UIScrollView) {
            guard let iv = scroll.viewWithTag(1) else { return }
            let offsetX = max((scroll.bounds.width  - iv.frame.width)  / 2, 0)
            let offsetY = max((scroll.bounds.height - iv.frame.height) / 2, 0)
            iv.frame.origin = CGPoint(x: offsetX, y: offsetY)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scroll = gesture.view as? UIScrollView else { return }
            if scroll.zoomScale > scroll.minimumZoomScale {
                scroll.setZoomScale(scroll.minimumZoomScale, animated: true)
            } else {
                let pt = gesture.location(in: scroll.viewWithTag(1))
                let zw = scroll.bounds.width  / scroll.maximumZoomScale
                let zh = scroll.bounds.height / scroll.maximumZoomScale
                let rect = CGRect(x: pt.x - zw / 2, y: pt.y - zh / 2, width: zw, height: zh)
                scroll.zoom(to: rect, animated: true)
            }
        }
    }
}

// MARK: - PDFRemoteReader
// Downloads a PDF from a remote URL and shows it with PDFKit.
// Uses singlePageContinuous mode — all pages scroll in one fluid view, pinch-to-zoom built-in.

private struct PDFRemoteReader: View {
    let url: URL
    var cornerRadius: CGFloat = 16

    @State private var pdfDocument: PDFDocument? = nil
    @State private var isLoading = true
    @State private var hasError  = false

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if hasError {
                errorView
            } else if let doc = pdfDocument {
                PDFKitView(document: doc)
                    .frame(minHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
            }
        }
        .onAppear { fetchPDF() }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.accent)
            Text("Loading PDF…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.textTertiary.opacity(0.5))
            Text("Could not load PDF")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
            Button("Try Again") { fetchPDF() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.accent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func fetchPDF() {
        isLoading = true
        hasError  = false
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                if let data, let doc = PDFDocument(data: data) {
                    pdfDocument = doc
                } else {
                    hasError = true
                }
            }
        }.resume()
    }
}

// MARK: - PDFKitView
// Wraps PDFKit's PDFView so all pages scroll vertically in one continuous view.
// PDFView has built-in pinch-to-zoom — no extra gesture recognizer needed.

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode      = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales       = false          // we manage scale manually
        pdfView.backgroundColor  = UIColor(Color.bg2)
        pdfView.document         = document
        pdfView.maxScaleFactor   = 4.0

        // Defer scale-to-fit until the view has a real frame from layout
        DispatchQueue.main.async {
            let fit = pdfView.scaleFactorForSizeToFit
            pdfView.minScaleFactor = fit * 0.8
            pdfView.scaleFactor    = fit
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard pdfView.document !== document else { return }
        pdfView.document = document
        DispatchQueue.main.async {
            let fit = pdfView.scaleFactorForSizeToFit
            pdfView.minScaleFactor = fit * 0.8
            pdfView.scaleFactor    = fit
        }
    }
}
