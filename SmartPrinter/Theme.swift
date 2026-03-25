import SwiftUI
import UIKit

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// "dark" | "light" | "system" — passed to JS bridge
    var jsValue: String { rawValue }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    @Published var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "app_theme") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "app_theme") ?? "system"
        current = AppTheme(rawValue: raw) ?? .system
    }

    var colorScheme: ColorScheme? { current.colorScheme }
}

// MARK: - Adaptive Color Helpers

private func adaptive(dark: UIColor, light: UIColor) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

private func uiHex(_ hex: String) -> UIColor {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    let r, g, b: UInt64
    switch h.count {
    case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    default: (r, g, b) = (128, 128, 128)
    }
    return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}

// MARK: - Color Palette
// Dark palette  → existing native colors
// Light palette → clean white/lavender tones matching the accent hue

extension Color {

    // ── Backgrounds ──────────────────────────────────────────────
    static let bg  = adaptive(dark: uiHex("#0a0a0f"), light: uiHex("#ffffff"))
    static let bg2 = adaptive(dark: uiHex("#12121a"), light: uiHex("#f3f3f8"))
    static let bg3 = adaptive(dark: uiHex("#1a1a26"), light: uiHex("#e8e8f0"))
    static let bg4 = adaptive(dark: uiHex("#22222f"), light: uiHex("#dcdcea"))

    // ── Accent ───────────────────────────────────────────────────
    static let accent  = adaptive(dark: uiHex("#6c63ff"), light: uiHex("#5b52e8"))
    static let accent2 = adaptive(dark: uiHex("#8b85ff"), light: uiHex("#6c63ff"))

    // ── Text ─────────────────────────────────────────────────────
    static let textPrimary   = adaptive(dark: uiHex("#f0f0f8"), light: uiHex("#0f0f1f"))
    static let textSecondary = adaptive(dark: uiHex("#9090b0"), light: uiHex("#50507a"))
    static let textTertiary  = adaptive(dark: uiHex("#5a5a7a"), light: uiHex("#8080a0"))

    // ── Status ───────────────────────────────────────────────────
    static let appGreen = adaptive(dark: uiHex("#34d399"), light: uiHex("#16a34a"))
    static let appAmber = adaptive(dark: uiHex("#fbbf24"), light: uiHex("#d97706"))
    static let appRed   = adaptive(dark: uiHex("#f87171"), light: uiHex("#dc2626"))
    static let appBlue  = adaptive(dark: uiHex("#60a5fa"), light: uiHex("#2563eb"))

    // ── Semantic backgrounds ──────────────────────────────────────
    static let greenBg    = Color.appGreen.opacity(0.12)
    static let amberBg    = Color.appAmber.opacity(0.12)
    static let redBg      = Color.appRed.opacity(0.12)
    static let blueBg     = Color.appBlue.opacity(0.12)
    static let accentGlow = Color.accent.opacity(0.25)

    // ── UI Chrome ─────────────────────────────────────────────────
    // Adaptive borders / dividers — replaces all Color.white.opacity(0.08/0.14)
    static let cardBorder   = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let dividerColor = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let btnBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.14)
            : UIColor.black.withAlphaComponent(0.09)
    })

    // MARK: - Hex init (kept for one-off uses)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - UIColor Accent (for UIKit usage)

extension UIColor {
    static let appAccent = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.424, green: 0.388, blue: 1.0, alpha: 1)   // #6c63ff
            : UIColor(red: 0.357, green: 0.322, blue: 0.910, alpha: 1)  // #5b52e8
    }
    static let appBackground = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1)  // #0a0a0f
            : UIColor.systemBackground
    }
    static let appLabel = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.941, blue: 0.973, alpha: 1)  // #f0f0f8
            : UIColor.label
    }
}

// MARK: - Reusable Components

struct AppCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct BadgeView: View {
    let text: String
    let fg: Color
    let bg: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(bg)
            .clipShape(Capsule())
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.bg3)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.btnBorder, lineWidth: 1))
        }
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textTertiary)
            .kerning(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(Color.bg3.opacity(0.97))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cardBorder, lineWidth: 1))
            .shadow(radius: 12)
    }
}
