// PDFToolsView.swift
// SwiftUI UIViewControllerRepresentable wrapper for PDFToolsViewController.

import SwiftUI

struct PDFToolsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        PDFToolsRepresentable(
            theme: themeManager.current,
            onDismiss: { dismiss() },
            onPrintFile: { url in vm.printFile(url: url) }
        )
        .ignoresSafeArea()
    }
}

// MARK: - UIViewControllerRepresentable

private struct PDFToolsRepresentable: UIViewControllerRepresentable {
    let theme: AppTheme
    let onDismiss: () -> Void
    let onPrintFile: (URL) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = PDFToolsViewController()
        vc.appTheme   = theme
        vc.onDismiss  = onDismiss
        vc.onPrintFile = onPrintFile

        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false
        applyNavBarAppearance(to: nav, theme: theme)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        applyNavBarAppearance(to: uiViewController, theme: theme)
        if let vc = uiViewController.viewControllers.first as? PDFToolsViewController {
            vc.applyTheme(theme)
        }
    }

    private func applyNavBarAppearance(to nav: UINavigationController, theme: AppTheme) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.appLabel]
        nav.navigationBar.standardAppearance   = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = .appAccent
        nav.overrideUserInterfaceStyle = theme.uiStyle
    }
}
