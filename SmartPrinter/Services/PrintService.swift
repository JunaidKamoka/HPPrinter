import UIKit

/// Minimal wrapper around UIPrintInteractionController.
/// The native print sheet handles printer selection, copies, page range,
/// paper size, duplex, color — everything. We just hand it the file.
class PrintService {

    /// Present the native iOS print sheet for a file URL.
    /// completion returns (userTappedPrint, estimatedPageCount).
    static func presentPrintSheet(
        url: URL,
        jobName: String? = nil,
        completion: @escaping (Bool, Int) -> Void
    ) {
        guard UIPrintInteractionController.canPrint(url) else {
            completion(false, 0)
            return
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.jobName = jobName ?? url.lastPathComponent
        info.outputType = isImageURL(url) ? .photo : .general

        controller.printInfo = info
        controller.printingItem = url
        controller.showsNumberOfCopies = true
        controller.showsPaperSelectionForLoadedPapers = true

        let pages = estimatePageCount(for: url)

        controller.present(animated: true) { _, completed, _ in
            completion(completed, pages)
        }
    }

    /// Present the native print sheet for raw Data (e.g. generated PDF).
    static func presentPrintSheet(
        data: Data,
        jobName: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard UIPrintInteractionController.canPrint(data) else {
            completion(false)
            return
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.jobName = jobName
        info.outputType = .general

        controller.printInfo = info
        controller.printingItem = data
        controller.showsNumberOfCopies = true
        controller.showsPaperSelectionForLoadedPapers = true

        controller.present(animated: true) { _, completed, _ in
            completion(completed)
        }
    }

    static func canPrint(_ url: URL) -> Bool {
        UIPrintInteractionController.canPrint(url)
    }

    static func estimatePageCount(for url: URL) -> Int {
        let ext = url.pathExtension.lowercased()
        if isImageExtension(ext) { return 1 }
        if ext == "pdf", let doc = CGPDFDocument(url as CFURL) {
            return doc.numberOfPages
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            return max(1, size / 3000)
        }
        return 1
    }

    static func isImageURL(_ url: URL) -> Bool {
        isImageExtension(url.pathExtension.lowercased())
    }

    private static func isImageExtension(_ ext: String) -> Bool {
        ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "bmp", "webp"].contains(ext)
    }
}
