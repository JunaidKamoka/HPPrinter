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
// Primary accent: #0149E1 (HP Blue)
// Light mode: white surfaces + HP blue accents
// Dark mode:  deep navy surfaces + bright blue accents

extension Color {

    // ── Backgrounds ──────────────────────────────────────────────
    static let bg  = adaptive(dark: uiHex("#060D1F"), light: uiHex("#FFFFFF"))
    static let bg2 = adaptive(dark: uiHex("#0B1530"), light: uiHex("#F0F5FF"))
    static let bg3 = adaptive(dark: uiHex("#111E40"), light: uiHex("#E1EAFD"))
    static let bg4 = adaptive(dark: uiHex("#172650"), light: uiHex("#D2E1FB"))

    // ── Accent (HP Blue) ─────────────────────────────────────────
    static let accent  = adaptive(dark: uiHex("#3D7EFF"), light: uiHex("#0149E1"))
    static let accent2 = adaptive(dark: uiHex("#6699FF"), light: uiHex("#0141C5"))

    // ── Text ─────────────────────────────────────────────────────
    static let textPrimary   = adaptive(dark: uiHex("#EEF2FF"), light: uiHex("#080E1F"))
    static let textSecondary = adaptive(dark: uiHex("#7A9DC8"), light: uiHex("#3A5080"))
    static let textTertiary  = adaptive(dark: uiHex("#3E5878"), light: uiHex("#7090B8"))

    // ── Status ───────────────────────────────────────────────────
    static let appGreen = adaptive(dark: uiHex("#34d399"), light: uiHex("#16a34a"))
    static let appAmber = adaptive(dark: uiHex("#fbbf24"), light: uiHex("#d97706"))
    static let appRed   = adaptive(dark: uiHex("#f87171"), light: uiHex("#dc2626"))
    static let appBlue  = adaptive(dark: uiHex("#3D7EFF"), light: uiHex("#0149E1"))

    // ── Semantic backgrounds ──────────────────────────────────────
    static let greenBg    = Color.appGreen.opacity(0.12)
    static let amberBg    = Color.appAmber.opacity(0.12)
    static let redBg      = Color.appRed.opacity(0.12)
    static let blueBg     = Color.appBlue.opacity(0.12)
    static let accentGlow = Color.accent.opacity(0.20)

    // ── UI Chrome ─────────────────────────────────────────────────
    static let cardBorder   = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor(red: 0.004, green: 0.286, blue: 0.882, alpha: 0.12)  // #0149E1 @ 12%
    })
    static let dividerColor = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.07)
            : UIColor(red: 0.004, green: 0.286, blue: 0.882, alpha: 0.10)
    })
    static let btnBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 0.004, green: 0.286, blue: 0.882, alpha: 0.18)
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
            ? UIColor(red: 0.239, green: 0.494, blue: 1.000, alpha: 1)  // #3D7EFF
            : UIColor(red: 0.004, green: 0.286, blue: 0.882, alpha: 1)  // #0149E1
    }
    static let appBackground = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.024, green: 0.051, blue: 0.122, alpha: 1)  // #060D1F
            : UIColor.white
    }
    static let appLabel = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.933, green: 0.949, blue: 1.000, alpha: 1)  // #EEF2FF
            : UIColor(red: 0.031, green: 0.055, blue: 0.122, alpha: 1)  // #080E1F
    }
}

// MARK: - Haptic Service

final class HapticService {
    static let shared = HapticService()
    private let key = "hp_haptics_enabled"
    private init() {}

    var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: key) == nil
                ? true
                : UserDefaults.standard.bool(forKey: key)
        }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
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
        Button {
            HapticService.shared.impact(.medium)
            action()
        } label: {
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
        Button {
            HapticService.shared.impact(.light)
            action()
        } label: {
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
