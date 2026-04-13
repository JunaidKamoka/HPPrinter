import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI

/// Coordinator for UIDocumentPickerViewController to pick files from Files app.
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .plainText, .rtf, .spreadsheet, .presentation,
                               UTType("com.microsoft.word.doc") ?? .data,
                               UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
                               UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data,
                               UTType("com.microsoft.powerpoint.ppt") ?? .data,
                               UTType("org.openxmlformats.presentationml.presentation") ?? .data,
                               .html, .webArchive]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

/// Coordinator for PHPickerViewController to pick photos.
struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                picker.dismiss(animated: true)
                return
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    guard let url = url else {
                        DispatchQueue.main.async { picker.dismiss(animated: true) }
                        return
                    }
                    // Copy to temp location since the provided URL is temporary
                    let dest = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    try? FileManager.default.copyItem(at: url, to: dest)
                    DispatchQueue.main.async {
                        // Dismiss picker first, then call onPick after dismiss completes
                        // to avoid "view not in window hierarchy" when presenting print sheet
                        picker.dismiss(animated: true) {
                            self.onPick(dest)
                        }
                    }
                }
            } else {
                picker.dismiss(animated: true)
            }
        }
    }
}
