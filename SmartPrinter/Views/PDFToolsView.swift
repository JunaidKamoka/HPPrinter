// PDFToolsView.swift
// SwiftUI UIViewControllerRepresentable wrapper for PDFToolsViewController.
// Presents the full WKWebView PDF Tools experience inside a SwiftUI sheet/fullScreenCover.

import SwiftUI

struct PDFToolsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        PDFToolsRepresentable(onDismiss: { dismiss() })
            .ignoresSafeArea()
    }
}

// MARK: - UIViewControllerRepresentable

private struct PDFToolsRepresentable: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = PDFToolsViewController()
        vc.onDismiss = onDismiss
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false
        // Match PrintMate dark theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.94, green: 0.94, blue: 0.97, alpha: 1)
        ]
        nav.navigationBar.standardAppearance   = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = UIColor(red: 0.42, green: 0.39, blue: 1.0, alpha: 1)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
