import SwiftUI
import VisionKit
import PDFKit

// MARK: - DocumentScannerView
// Wraps VNDocumentCameraViewController, converts all scanned pages to a PDF,
// and returns the PDF URL via the onScan callback.

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (URL) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan:   (URL) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onScan   = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Collect all scanned page images
            var pages: [UIImage] = []
            for i in 0..<scan.pageCount {
                pages.append(scan.imageOfPage(at: i))
            }

            // Convert images → PDF in background, then call back on main
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let pdfURL = Self.buildPDF(from: pages)
                DispatchQueue.main.async {
                    if let url = pdfURL {
                        self.onScan(url)
                    } else {
                        self.onCancel()
                    }
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            NSLog("[Scanner] failed: %@", error.localizedDescription)
            DispatchQueue.main.async { self.onCancel() }
        }

        // MARK: - PDF builder

        /// Renders each UIImage as an A4 page in a PDF.
        private static func buildPDF(from images: [UIImage]) -> URL? {
            guard !images.isEmpty else { return nil }

            let a4 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 @ 72 dpi
            let renderer = UIGraphicsPDFRenderer(bounds: a4)

            let pdfData = renderer.pdfData { ctx in
                for image in images {
                    ctx.beginPage()
                    // Fit image into A4, preserving aspect ratio, centred
                    let imgSize  = image.size
                    let scale    = min(a4.width / imgSize.width, a4.height / imgSize.height)
                    let drawSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
                    let origin   = CGPoint(
                        x: (a4.width  - drawSize.width)  / 2,
                        y: (a4.height - drawSize.height) / 2
                    )
                    image.draw(in: CGRect(origin: origin, size: drawSize))
                }
            }

            // Write to a uniquely-named temp file
            let fileName = "Scan_\(Int(Date().timeIntervalSince1970)).pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try pdfData.write(to: url)
                return url
            } catch {
                NSLog("[Scanner] PDF write error: %@", error.localizedDescription)
                return nil
            }
        }
    }
}
