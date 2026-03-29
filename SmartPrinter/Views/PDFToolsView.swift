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
            onPrintFile: { url in vm.printFile(url: url, source: "PDF Tools") },
            onToolUsed: { vm.checkAccess() }
        )
        .ignoresSafeArea()
    }
}

// MARK: - UIViewControllerRepresentable

private struct PDFToolsRepresentable: UIViewControllerRepresentable {
    let theme: AppTheme
    let onDismiss: () -> Void
    let onPrintFile: (URL) -> Void
    let onToolUsed: () -> Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = PDFToolsViewController()
        vc.appTheme   = theme
        vc.onDismiss  = onDismiss
        vc.onPrintFile = onPrintFile
        vc.onToolUsed  = onToolUsed

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
        let isDark = theme.uiStyle == .dark
        let bgColor  = isDark ? UIColor(red: 0.024, green: 0.051, blue: 0.122, alpha: 1) : UIColor.white
        let fgColor  = isDark ? UIColor(red: 0.933, green: 0.949, blue: 1.000, alpha: 1) : UIColor(red: 0.031, green: 0.055, blue: 0.122, alpha: 1)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bgColor
        appearance.titleTextAttributes = [.foregroundColor: fgColor]
        let whiteAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: fgColor]
        appearance.buttonAppearance.normal.titleTextAttributes = whiteAttrs
        appearance.doneButtonAppearance.normal.titleTextAttributes = whiteAttrs
        nav.navigationBar.standardAppearance   = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = fgColor
        nav.overrideUserInterfaceStyle = theme.uiStyle
    }
}
