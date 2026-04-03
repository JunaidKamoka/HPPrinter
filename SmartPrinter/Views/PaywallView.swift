import SwiftUI
import StoreKit

// MARK: - Paywall Entry Point
// Shows a different visual style each time based on paywallVariant (0,1,2)

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    var onDismiss: (() -> Void)?
    var freePrintsRemaining: Int = 0
    var variant: Int = 0   // 0=Minimal, 1=Dark, 2=Focused

    var body: some View {
        switch variant % 3 {
        case 1:  PaywallDark(onDismiss: onDismiss, freePrintsRemaining: freePrintsRemaining)
                    .environmentObject(subscriptionService)
        case 2:  PaywallFocused(onDismiss: onDismiss, freePrintsRemaining: freePrintsRemaining)
                    .environmentObject(subscriptionService)
        default: PaywallMinimal(onDismiss: onDismiss, freePrintsRemaining: freePrintsRemaining)
                    .environmentObject(subscriptionService)
        }
    }
}

// MARK: ─────────────────────────────────────────────
// STYLE A · Minimal  (clean white / blue, slide-up)
// ─────────────────────────────────────────────────

struct PaywallMinimal: View {
    @EnvironmentObject var sub: SubscriptionService
    var onDismiss: (() -> Void)?
    var freePrintsRemaining: Int = 0

    @State private var appeared = false
    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var showError    = false
    @State private var errorMsg     = ""

    @Environment(\.colorScheme) private var scheme

    private var blue: Color  { Color(hex: "#0149E1") }
    private var bg: Color    { scheme == .dark ? Color(hex: "#060D1F") : Color(hex: "#F5F7FF") }
    private var card: Color  { scheme == .dark ? Color(hex: "#111E40") : .white }
    private var fg: Color    { scheme == .dark ? .white : Color(hex: "#0D0D0D") }
    private var fg2: Color   { scheme == .dark ? Color.white.opacity(0.55) : Color(hex: "#0D0D0D").opacity(0.5) }
    private var line: Color  { scheme == .dark ? Color.white.opacity(0.08) : blue.opacity(0.10) }

    let features: [(String,String)] = [
        ("Unlimited PDF Tools",     "Merge, split, convert, compress & more"),
        ("Unlimited Form Printing", "Print any form with all pages at once"),
        ("Unlimited Printables",    "Download & print any template instantly"),
        ("Advanced Editing",        "Edit, annotate & sign PDF documents"),
        ("No Watermarks",           "Clean, professional output every time"),
        ("Priority Processing",     "Faster uploads & processing speed"),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            bg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Close
                    HStack {
                        Spacer()
                        Button { onDismiss?() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(fg2)
                                .frame(width: 32, height: 32)
                                .background(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, safeTop + 8)
                    .padding(.horizontal, 20)

                    // Crown
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(blue.opacity(0.10)).frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(LinearGradient(colors: [Color(hex:"#FFD700"), Color(hex:"#FFA500")], startPoint: .top, endPoint: .bottom))
                        }
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65), value: appeared)

                        Text("Go Premium")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(fg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.08), value: appeared)

                        Text("Unlock unlimited access to all features")
                            .font(.system(size: 14))
                            .foregroundColor(fg2)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.4).delay(0.14), value: appeared)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Feature list card
                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { idx, f in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(blue)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.0).font(.system(size: 14, weight: .semibold)).foregroundColor(fg)
                                    Text(f.1).font(.system(size: 12)).foregroundColor(fg2).lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 11).padding(.horizontal, 16)
                            if idx < features.count - 1 {
                                Divider().background(line).padding(.leading, 46)
                            }
                        }
                    }
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(line, lineWidth: 1))
                    .shadow(color: blue.opacity(scheme == .dark ? 0 : 0.06), radius: 10, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.45).delay(0.18), value: appeared)

                    // Free tries badge
                    if freePrintsRemaining == 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Color(hex:"#FF9500")).font(.system(size: 12))
                            Text("You've used all free actions — upgrade to continue")
                                .font(.system(size: 12, weight: .medium)).foregroundColor(fg)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex:"#FF9500").opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex:"#FF9500").opacity(0.30), lineWidth: 1))
                        .padding(.horizontal, 20).padding(.top, 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.22), value: appeared)
                    }

                    // Plan cards
                    minimalPlanCards
                        .padding(.horizontal, 20).padding(.top, 18)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 18)
                        .animation(.easeOut(duration: 0.45).delay(0.26), value: appeared)

                    // CTA
                    ctaButton
                        .padding(.horizontal, 20).padding(.top, 18)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.32), value: appeared)

                    // Footer
                    paywallFooter(fg2: fg2, isRestoring: isRestoring) {
                        Task { isRestoring = true; await sub.restorePurchases(); isRestoring = false
                            if sub.isPremium { onDismiss?() }
                        }
                    } onDismiss: { onDismiss?() }
                    .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.38), value: appeared)
                }
            }
        }
        .ignoresSafeArea()
        .task { await loadAndSelect() }
        .alert("Error", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(errorMsg) }
        .onChange(of: sub.purchaseError) { err in guard let err else { return }; errorMsg = err; showError = true }
    }

    var minimalPlanCards: some View {
        Group {
            if sub.weeklyProduct != nil || sub.monthlyProduct != nil {
                HStack(spacing: 12) {
                    if let w = sub.weeklyProduct  { minCard(w, label: "Weekly",  best: false) }
                    if let m = sub.monthlyProduct { minCard(m, label: "Monthly", best: true)  }
                }
            } else {
                planLoadingPlaceholder(fg: fg, fg2: fg2, card: card, line: line)
            }
        }
    }

    func minCard(_ product: Product, label: String, best: Bool) -> some View {
        let sel = selectedProduct?.id == product.id
        let trial = sub.trialDays(for: product)
        return Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedProduct = product } } label: {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if best {
                        Text("BEST VALUE").font(.system(size: 9, weight: .bold))
                            .foregroundColor(sel ? .white : blue)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(sel ? blue : blue.opacity(0.12)).clipShape(Capsule())
                    }
                    if let d = trial {
                        Text("\(d)-Day Free").font(.system(size: 9, weight: .bold))
                            .foregroundColor(sel ? .white : Color(hex:"#00A878"))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(sel ? Color(hex:"#00A878") : Color(hex:"#00A878").opacity(0.12)).clipShape(Capsule())
                    }
                    if !best && trial == nil { Color.clear.frame(height: 18) }
                }.frame(height: 18)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(sel ? blue : fg2)
                Text(sub.periodLabel(for: product)).font(.system(size: 17, weight: .bold)).foregroundColor(fg).minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 10)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(sel ? blue : line, lineWidth: sel ? 2 : 1))
            .shadow(color: sel ? blue.opacity(0.18) : .clear, radius: 10, y: 4)
        }.buttonStyle(.plain)
    }

    var ctaButton: some View {
        VStack(spacing: 8) {
            Button {
                guard !isPurchasing, let p = selectedProduct else { return }
                Task { isPurchasing = true; let ok = await sub.purchase(p); isPurchasing = false; if ok { onDismiss?() } }
            } label: {
                ZStack {
                    if isPurchasing { ProgressView().tint(.white) }
                    else { Text(sub.ctaLabel(selectedProduct: selectedProduct)).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white) }
                }
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(LinearGradient(colors: [Color(hex:"#0149E1"), Color(hex:"#3D7EFF")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: blue.opacity(0.30), radius: 10, y: 4)
            }.disabled(isPurchasing || selectedProduct == nil)

            if let p = selectedProduct, let sub2 = sub.subLabel(for: p) {
                Text(sub2).font(.system(size: 11)).foregroundColor(fg2).multilineTextAlignment(.center)
            }
        }
    }

    func loadAndSelect() async {
        await sub.loadProducts()
        if selectedProduct == nil { selectedProduct = sub.monthlyProduct ?? sub.weeklyProduct }
        withAnimation { appeared = true }
    }
}

// MARK: ─────────────────────────────────────────────
// STYLE B · Dark Impact  (dark bg, grid features, morph)
// ─────────────────────────────────────────────────

struct PaywallDark: View {
    @EnvironmentObject var sub: SubscriptionService
    var onDismiss: (() -> Void)?
    var freePrintsRemaining: Int = 0

    @State private var appeared   = false
    @State private var morphA     = false
    @State private var morphB     = false
    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var showError    = false
    @State private var errorMsg     = ""

    private let blue  = Color(hex: "#0149E1")
    private let blue2 = Color(hex: "#3D7EFF")
    private let dark1 = Color(hex: "#060D1F")
    private let dark2 = Color(hex: "#0B1530")
    private let dark3 = Color(hex: "#111E40")

    let gridFeatures: [(icon: String, label: String)] = [
        ("doc.on.doc.fill",          "Merge PDF"),
        ("scissors",                 "Split PDF"),
        ("doc.text.fill",            "PDF to Word"),
        ("wand.and.stars",           "Edit & Sign"),
        ("checkmark.shield.fill",    "No Watermarks"),
        ("bolt.fill",                "Fast Processing"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [dark1, dark2, dark1], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Morphing orbs
            Circle().fill(blue.opacity(0.25)).frame(width: 320, height: 320).blur(radius: 80)
                .offset(x: morphA ? 80 : -60, y: morphA ? -100 : -160)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: morphA)
            Circle().fill(blue2.opacity(0.18)).frame(width: 240, height: 240).blur(radius: 60)
                .offset(x: morphB ? -80 : 60, y: morphB ? 200 : 140)
                .animation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true), value: morphB)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Close
                    HStack {
                        Spacer()
                        Button { onDismiss?() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, safeTop + 8)
                    .padding(.horizontal, 20)

                    // Crown + title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(LinearGradient(colors: [Color(hex:"#FFD700").opacity(0.8), Color(hex:"#FFD700").opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                                .frame(width: 90, height: 90)
                                .rotationEffect(.degrees(appeared ? 360 : 0))
                                .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: appeared)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(LinearGradient(colors: [Color(hex:"#FFD700"), Color(hex:"#FFA500")], startPoint: .top, endPoint: .bottom))
                        }
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65), value: appeared)

                        Text("Unlock Everything")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.white, Color(hex:"#D6E8FF")], startPoint: .top, endPoint: .bottom))
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                        Text("One subscription. Every feature.")
                            .font(.system(size: 15)).foregroundColor(.white.opacity(0.6))
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 14)
                            .animation(.easeOut(duration: 0.45).delay(0.16), value: appeared)
                    }
                    .padding(.top, 10).padding(.horizontal, 24)

                    // Feature grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(gridFeatures.enumerated()), id: \.offset) { idx, f in
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12).fill(blue.opacity(0.20)).frame(width: 46, height: 46)
                                    Image(systemName: f.icon).font(.system(size: 20)).foregroundColor(blue2)
                                }
                                Text(f.label).font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.85)).multilineTextAlignment(.center).lineLimit(2)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.85)
                            .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.22 + Double(idx) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 28)

                    // Plan cards
                    darkPlanCards
                        .padding(.horizontal, 20).padding(.top, 24)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 22)
                        .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)

                    // CTA
                    darkCTA
                        .padding(.horizontal, 20).padding(.top, 18)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.44), value: appeared)

                    paywallFooter(fg2: .white.opacity(0.40), isRestoring: isRestoring) {
                        Task { isRestoring = true; await sub.restorePurchases(); isRestoring = false; if sub.isPremium { onDismiss?() } }
                    } onDismiss: { onDismiss?() }
                    .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.50), value: appeared)
                }
            }
        }
        .ignoresSafeArea()
        .task { await sub.loadProducts(); if selectedProduct == nil { selectedProduct = sub.monthlyProduct ?? sub.weeklyProduct }
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { morphA = true; morphB = true }
        }
        .alert("Error", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(errorMsg) }
        .onChange(of: sub.purchaseError) { err in guard let err else { return }; errorMsg = err; showError = true }
    }

    var darkPlanCards: some View {
        Group {
            if sub.weeklyProduct != nil || sub.monthlyProduct != nil {
                HStack(spacing: 12) {
                    if let w = sub.weeklyProduct  { darkCard(w, label: "Weekly",  best: false) }
                    if let m = sub.monthlyProduct { darkCard(m, label: "Monthly", best: true)  }
                }
            } else {
                planLoadingPlaceholder(fg: .white, fg2: .white.opacity(0.5), card: Color.white.opacity(0.07), line: Color.white.opacity(0.12))
            }
        }
    }

    func darkCard(_ product: Product, label: String, best: Bool) -> some View {
        let sel = selectedProduct?.id == product.id
        let trial = sub.trialDays(for: product)
        return Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedProduct = product } } label: {
            VStack(spacing: 7) {
                if best {
                    Text("BEST VALUE").font(.system(size: 9, weight: .bold))
                        .foregroundColor(sel ? dark1 : Color(hex:"#FFD700"))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(sel ? Color(hex:"#FFD700") : Color(hex:"#FFD700").opacity(0.18))
                        .clipShape(Capsule())
                } else { Color.clear.frame(height: 18) }

                Text(label).font(.system(size: 14, weight: .bold)).foregroundColor(sel ? .white : .white.opacity(0.6))

                if let d = trial {
                    Text("\(d)-Day Free").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex:"#34C759"))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex:"#34C759").opacity(0.15)).clipShape(Capsule())
                }

                Text(sub.periodLabel(for: product)).font(.system(size: 16, weight: .heavy))
                    .foregroundColor(sel ? .white : .white.opacity(0.55))
                    .minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 10)
            .background(sel
                ? LinearGradient(colors: [blue.opacity(0.55), dark3], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(sel ? blue2 : Color.white.opacity(0.12), lineWidth: sel ? 2 : 1))
        }.buttonStyle(.plain)
    }

    var darkCTA: some View {
        VStack(spacing: 8) {
            Button {
                guard !isPurchasing, let p = selectedProduct else { return }
                Task { isPurchasing = true; let ok = await sub.purchase(p); isPurchasing = false; if ok { onDismiss?() } }
            } label: {
                ZStack {
                    if isPurchasing { ProgressView().tint(.white) }
                    else { Text(sub.ctaLabel(selectedProduct: selectedProduct)).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.white) }
                }
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(LinearGradient(colors: [blue, blue2], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: blue.opacity(0.50), radius: 16, y: 6)
            }.disabled(isPurchasing || selectedProduct == nil)

            if let p = selectedProduct, let s = sub.subLabel(for: p) {
                Text(s).font(.system(size: 11)).foregroundColor(.white.opacity(0.45)).multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: ─────────────────────────────────────────────
// STYLE C · Focused  (light, hero price, bounce anim)
// ─────────────────────────────────────────────────

struct PaywallFocused: View {
    @EnvironmentObject var sub: SubscriptionService
    var onDismiss: (() -> Void)?
    var freePrintsRemaining: Int = 0

    @State private var appeared      = false
    @State private var ringRotate    = false
    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing  = false
    @State private var isRestoring   = false
    @State private var showError     = false
    @State private var errorMsg      = ""

    @Environment(\.colorScheme) private var scheme

    private var blue: Color  { Color(hex: "#0149E1") }
    private var bg: Color    { scheme == .dark ? Color(hex: "#060D1F") : .white }
    private var card: Color  { scheme == .dark ? Color(hex: "#0D1A36") : Color(hex: "#F0F5FF") }
    private var fg: Color    { scheme == .dark ? .white : Color(hex: "#0D0D0D") }
    private var fg2: Color   { scheme == .dark ? Color.white.opacity(0.50) : Color(hex: "#0D0D0D").opacity(0.45) }
    private var line: Color  { scheme == .dark ? Color.white.opacity(0.08) : blue.opacity(0.12) }

    let pillFeatures = [
        ("printer.fill",     "Unlimited Printing"),
        ("doc.on.doc.fill",  "All PDF Tools"),
        ("checkmark.shield", "No Watermarks"),
        ("bolt.fill",        "Priority Speed"),
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // Close
                HStack {
                    Spacer()
                    Button { onDismiss?() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(fg2)
                            .frame(width: 32, height: 32)
                            .background(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, safeTop + 8)
                .padding(.horizontal, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Animated crown with rotating ring
                        ZStack {
                            // Outer dashed ring
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .fill(blue.opacity(0.0))
                                .overlay(
                                    Circle().stroke(blue.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                )
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(ringRotate ? 360 : 0))
                                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: ringRotate)

                            // Inner fill
                            Circle()
                                .fill(LinearGradient(colors: [blue.opacity(0.15), blue.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 86, height: 86)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(LinearGradient(colors: [Color(hex:"#FFD700"), Color(hex:"#FFA500")], startPoint: .top, endPoint: .bottom))
                        }
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)
                        .padding(.top, 20)

                        Text("Go Premium")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(fg)
                            .padding(.top, 14)
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 18)
                            .animation(.easeOut(duration: 0.45).delay(0.10), value: appeared)

                        // Feature pills
                        VStack(spacing: 10) {
                            ForEach(Array(pillFeatures.enumerated()), id: \.offset) { idx, f in
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle().fill(blue.opacity(0.12)).frame(width: 34, height: 34)
                                        Image(systemName: f.0).font(.system(size: 14)).foregroundColor(blue)
                                    }
                                    Text(f.1).font(.system(size: 15, weight: .semibold)).foregroundColor(fg)
                                    Spacer()
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(blue)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(line, lineWidth: 1))
                                .opacity(appeared ? 1 : 0)
                                .offset(x: appeared ? 0 : (idx % 2 == 0 ? -40 : 40))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.18 + Double(idx) * 0.08), value: appeared)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 22)

                        // Plan cards
                        Group {
                            if sub.weeklyProduct != nil || sub.monthlyProduct != nil {
                                HStack(spacing: 12) {
                                    if let w = sub.weeklyProduct  { focusedCard(w, label: "Weekly",  best: false) }
                                    if let m = sub.monthlyProduct { focusedCard(m, label: "Monthly", best: true)  }
                                }
                            } else {
                                planLoadingPlaceholder(fg: fg, fg2: fg2, card: card, line: line)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 22)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.45).delay(0.50), value: appeared)

                        // CTA
                        VStack(spacing: 8) {
                            Button {
                                guard !isPurchasing, let p = selectedProduct else { return }
                                Task { isPurchasing = true; let ok = await sub.purchase(p); isPurchasing = false; if ok { onDismiss?() } }
                            } label: {
                                ZStack {
                                    if isPurchasing { ProgressView().tint(.white) }
                                    else { Text(sub.ctaLabel(selectedProduct: selectedProduct)).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white) }
                                }
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(LinearGradient(colors: [blue, Color(hex:"#3D7EFF")], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: blue.opacity(0.28), radius: 12, y: 4)
                            }.disabled(isPurchasing || selectedProduct == nil)

                            if let p = selectedProduct, let s = sub.subLabel(for: p) {
                                Text(s).font(.system(size: 11)).foregroundColor(fg2).multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 20)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.56), value: appeared)

                        paywallFooter(fg2: fg2, isRestoring: isRestoring) {
                            Task { isRestoring = true; await sub.restorePurchases(); isRestoring = false; if sub.isPremium { onDismiss?() } }
                        } onDismiss: { onDismiss?() }
                        .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 36)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.62), value: appeared)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .task { await sub.loadProducts(); if selectedProduct == nil { selectedProduct = sub.monthlyProduct ?? sub.weeklyProduct }
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { ringRotate = true }
        }
        .alert("Error", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(errorMsg) }
        .onChange(of: sub.purchaseError) { err in guard let err else { return }; errorMsg = err; showError = true }
    }

    func focusedCard(_ product: Product, label: String, best: Bool) -> some View {
        let sel = selectedProduct?.id == product.id
        let trial = sub.trialDays(for: product)
        return Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedProduct = product } } label: {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if best {
                        Text("BEST VALUE").font(.system(size: 9, weight: .bold))
                            .foregroundColor(sel ? .white : blue)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(sel ? blue : blue.opacity(0.12)).clipShape(Capsule())
                    }
                    if let d = trial {
                        Text("\(d)-Day Free").font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex:"#00A878"))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color(hex:"#00A878").opacity(0.12)).clipShape(Capsule())
                    }
                    if !best && trial == nil { Color.clear.frame(height: 18) }
                }.frame(height: 18)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(sel ? blue : fg2)
                Text(sub.periodLabel(for: product)).font(.system(size: 17, weight: .bold)).foregroundColor(fg).minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 10)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(sel ? blue : line, lineWidth: sel ? 2 : 1))
            .shadow(color: sel ? blue.opacity(0.16) : .clear, radius: 10, y: 4)
        }.buttonStyle(.plain)
    }
}

// MARK: - Shared helpers

private var safeTop: CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.top ?? 44
}

private func planLoadingPlaceholder(fg: Color, fg2: Color, card: Color, line: Color) -> some View {
    VStack(spacing: 12) {
        ProgressView()
            .tint(fg2)
        Text("Loading plans...")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(fg2)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
    .background(card)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(line, lineWidth: 1))
}

private func paywallFooter(fg2: Color, isRestoring: Bool, onRestore: @escaping () -> Void, onDismiss: @escaping () -> Void) -> some View {
    HStack(spacing: 16) {
        Button {
            onRestore()
        } label: {
            Group {
                if isRestoring { ProgressView().scaleEffect(0.7) }
                else { Text("Restore").font(.system(size: 12, weight: .medium)).foregroundColor(fg2) }
            }
        }
        Text("·").foregroundColor(fg2).font(.system(size: 12))
        Button {
            UIApplication.shared.open(URL(string: "https://appchunks.com/terms")!)
        } label: {
            Text("Terms").font(.system(size: 12, weight: .medium)).foregroundColor(fg2)
        }
        Text("·").foregroundColor(fg2).font(.system(size: 12))
        Button {
            UIApplication.shared.open(URL(string: "https://appchunks.com/privacy")!)
        } label: {
            Text("Privacy").font(.system(size: 12, weight: .medium)).foregroundColor(fg2)
        }
    }
    .frame(maxWidth: .infinity)
}
