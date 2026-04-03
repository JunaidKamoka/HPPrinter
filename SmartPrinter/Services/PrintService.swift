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
        let name = jobName ?? url.lastPathComponent
        NSLog("[Print] ── presentPrintSheet(url) ──")
        NSLog("[Print]   file: %@", url.lastPathComponent)
        NSLog("[Print]   path: %@", url.path)
        NSLog("[Print]   ext:  %@", url.pathExtension.lowercased())
        NSLog("[Print]   exists: %@", FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")

        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            NSLog("[Print]   size: %d bytes (%.1f KB)", size, Double(size) / 1024.0)
        } else {
            NSLog("[Print]   size: UNKNOWN (cannot read attributes)")
        }

        let canPrintResult = UIPrintInteractionController.canPrint(url)
        NSLog("[Print]   canPrint: %@", canPrintResult ? "YES" : "NO")

        guard canPrintResult else {
            NSLog("[Print]   ❌ ABORT — canPrint returned false for: %@", url.lastPathComponent)
            completion(false, 0)
            return
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.jobName = name
        info.outputType = isImageURL(url) ? .photo : .general
        NSLog("[Print]   jobName: %@", name)
        NSLog("[Print]   outputType: %@", isImageURL(url) ? "photo" : "general")

        controller.printInfo = info
        controller.printingItem = url
        controller.showsNumberOfCopies = true
        controller.showsPaperSelectionForLoadedPapers = true

        let pages = estimatePageCount(for: url)
        NSLog("[Print]   estimatedPages: %d", pages)
        NSLog("[Print]   presenting print sheet...")

        presentController(controller) { completed in
            NSLog("[Print]   ── RESULT ──")
            NSLog("[Print]   completed: %@", completed ? "YES (printed)" : "NO (cancelled)")
            completion(completed, pages)
        }
    }

    /// Present the native print sheet for raw Data (e.g. generated PDF).
    static func presentPrintSheet(
        data: Data,
        jobName: String,
        completion: @escaping (Bool) -> Void
    ) {
        NSLog("[Print] ── presentPrintSheet(data) ──")
        NSLog("[Print]   jobName: %@", jobName)
        NSLog("[Print]   dataSize: %d bytes (%.1f KB)", data.count, Double(data.count) / 1024.0)

        let canPrintResult = UIPrintInteractionController.canPrint(data)
        NSLog("[Print]   canPrint(data): %@", canPrintResult ? "YES" : "NO")

        guard canPrintResult else {
            NSLog("[Print]   ❌ ABORT — canPrint(data) returned false")
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

        NSLog("[Print]   presenting print sheet (data)...")

        presentController(controller) { completed in
            NSLog("[Print]   ── RESULT (data) ──")
            NSLog("[Print]   completed: %@", completed ? "YES (printed)" : "NO (cancelled)")
            completion(completed)
        }
    }

    /// Find the topmost view controller and present the print sheet from it.
    /// Accepts foregroundActive OR foregroundInactive scenes (the latter happens
    /// right after a document-picker sheet dismisses while the scene transitions).
    /// Retries once after a short delay if no scene is available yet.
    private static func presentController(
        _ controller: UIPrintInteractionController,
        completion: @escaping (Bool) -> Void,
        retryCount: Int = 0
    ) {
        // Accept both foregroundActive and foregroundInactive scenes
        let windowScene: UIWindowScene? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundInactive })

        // Find the key window, or fall back to any visible window
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
                  ?? windowScene?.windows.first

        guard let windowScene, let window, let rootVC = window.rootViewController else {
            NSLog("[Print]   ⚠️ No usable window scene (retry=%d)", retryCount)
            for scene in UIApplication.shared.connectedScenes {
                NSLog("[Print]     scene: %@ state=%ld", scene.description, scene.activationState.rawValue)
            }
            // Retry once after a short delay — scene may still be transitioning
            if retryCount < 2 {
                let delay = retryCount == 0 ? 0.5 : 1.0
                NSLog("[Print]   ⏳ Retrying in %.1fs...", delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    presentController(controller, completion: completion, retryCount: retryCount + 1)
                }
            } else {
                NSLog("[Print]   ❌ ABORT — no window scene after %d retries", retryCount)
                completion(false)
            }
            return
        }

        NSLog("[Print]   windowScene state: %ld", windowScene.activationState.rawValue)

        // Walk the presentation chain to find the topmost VC
        var topVC = rootVC
        var depth = 0
        while let presented = topVC.presentedViewController {
            topVC = presented
            depth += 1
        }
        NSLog("[Print]   rootVC: %@", String(describing: type(of: rootVC)))
        NSLog("[Print]   topVC:  %@ (depth=%d)", String(describing: type(of: topVC)), depth)

        let presented = controller.present(from: topVC.view.bounds,
                                           in: topVC.view,
                                           animated: true) { _, completed, error in
            if let error = error {
                NSLog("[Print]   ⚠️ print error: %@", error.localizedDescription)
            }
            completion(completed)
        }
        NSLog("[Print]   present() returned: %@", presented ? "true (sheet shown)" : "false (sheet NOT shown)")
        if !presented {
            // If present() fails, retry once — the scene might not be fully ready
            if retryCount < 2 {
                NSLog("[Print]   ⏳ present() failed, retrying in 0.5s...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentController(controller, completion: completion, retryCount: retryCount + 1)
                }
            } else {
                NSLog("[Print]   ❌ ABORT — present() failed after %d retries", retryCount)
                completion(false)
            }
        }
    }

    static func canPrint(_ url: URL) -> Bool {
        let result = UIPrintInteractionController.canPrint(url)
        NSLog("[Print] canPrint(%@) → %@", url.lastPathComponent, result ? "YES" : "NO")
        return result
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
