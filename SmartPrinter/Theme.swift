import SwiftUI

extension Color {
    static let bg       = Color(hex: "#0a0a0f")
    static let bg2      = Color(hex: "#12121a")
    static let bg3      = Color(hex: "#1a1a26")
    static let bg4      = Color(hex: "#22222f")
    static let accent   = Color(hex: "#6c63ff")
    static let accent2  = Color(hex: "#8b85ff")
    static let textPrimary   = Color(hex: "#f0f0f8")
    static let textSecondary = Color(hex: "#9090b0")
    static let textTertiary  = Color(hex: "#5a5a7a")
    static let appGreen = Color(hex: "#34d399")
    static let appAmber = Color(hex: "#fbbf24")
    static let appRed   = Color(hex: "#f87171")
    static let appBlue  = Color(hex: "#60a5fa")

    static let greenBg  = Color(hex: "#34d399").opacity(0.12)
    static let amberBg  = Color(hex: "#fbbf24").opacity(0.12)
    static let redBg    = Color(hex: "#f87171").opacity(0.12)
    static let blueBg   = Color(hex: "#60a5fa").opacity(0.12)
    static let accentGlow = Color(hex: "#6c63ff").opacity(0.25)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

struct AppCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
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
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.14), lineWidth: 1))
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
            .background(Color(hex: "#1e1e2d").opacity(0.95))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
            .shadow(radius: 12)
    }
}
