import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionService: SubscriptionService

    let qualities = ["Best", "Normal", "Draft", "Economy"]

    // All modal state lives here — never on child buttons/cards
    @State private var showPaywallFromSettings  = false
    @State private var activePaywallVariant     = 0
    @State private var showTestPrintPicker      = false
    @State private var showClearHistoryConfirm  = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Subscription ───────────────────────────────────
                        SectionTitle(text: "Subscription").padding(.horizontal).padding(.top, 8)
                        AppCard {
                            Button {
                                if subscriptionService.isPremium {
                                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                        UIApplication.shared.open(url)
                                    }
                                } else {
                                    activePaywallVariant = vm.paywallVariant
                                    vm.nextPaywallVariant()
                                    showPaywallFromSettings = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(subscriptionService.isPremium ? "Premium Active" : "Upgrade to Premium")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                        Text(subscriptionService.isPremium
                                             ? "Manage your subscription"
                                             : "\(vm.freePrintsRemaining) free action\(vm.freePrintsRemaining == 1 ? "" : "s") remaining")
                                            .font(.system(size: 12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    if subscriptionService.isPremium {
                                        Text("ACTIVE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(hex: "#34C759"))
                                            .padding(.horizontal, 7).padding(.vertical, 3)
                                            .background(Color(hex: "#34C759").opacity(0.14))
                                            .clipShape(Capsule())
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal).padding(.bottom, 6)

                        // ── Appearance ─────────────────────────────────────
                        SectionTitle(text: "Appearance").padding(.horizontal).padding(.top, 8)
                        AppCard {
                            VStack(spacing: 0) {
                                HStack {
                                    Label("Theme", systemImage: themeManager.current.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                HStack(spacing: 6) {
                                    ForEach(AppTheme.allCases, id: \.self) { theme in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                themeManager.current = theme
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: theme.icon).font(.system(size: 12))
                                                Text(theme.displayName).font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundColor(themeManager.current == theme ? .white : .textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(themeManager.current == theme ? Color.accent : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 9))
                                            .frame(maxWidth: .infinity)
                                            .contentShape(Rectangle())
                                        }
                                    }
                                }
                                .padding(4)
                                .background(Color.bg4)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 16)

                        VStack(alignment: .leading, spacing: 10) {

                            // ── Print Defaults ─────────────────────────────
                            SectionTitle(text: "Print Defaults")
                            AppCard {
                                SegmentRow(label: "Color Mode", options: ["Color", "B&W"], selection: $vm.colorMode)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                HStack {
                                    Text("Print Quality").font(.system(size: 14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Picker("", selection: $vm.printQuality) {
                                        ForEach(qualities, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.menu).tint(.textSecondary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Two-sided (Duplex)", isOn: $vm.duplexEnabled)
                            }

                            // ── App Behavior ───────────────────────────────
                            SectionTitle(text: "App Behavior").padding(.top, 8)
                            AppCard {
                                ToggleRow(label: "Notifications", isOn: $vm.notificationsEnabled)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Auto-reconnect Printer", isOn: $vm.autoReconnect)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Print in Background", isOn: $vm.printInBackground)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Save to History", isOn: $vm.saveHistory)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                HapticsToggleRow(isOn: Binding(
                                    get: { vm.hapticsEnabled },
                                    set: { vm.hapticsEnabled = $0 }
                                ))
                            }

                            // ── Print History ──────────────────────────────
                            SectionTitle(text: "Print History").padding(.top, 8)
                            AppCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Total Printed").font(.system(size: 14)).foregroundColor(.textPrimary)
                                        Text("\(vm.totalPagesPrinted) pages across \(vm.history.count) jobs")
                                            .font(.system(size: 12)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 18)).foregroundColor(.accent)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                Button {
                                    showClearHistoryConfirm = true
                                } label: {
                                    HStack {
                                        Text("Clear Print History")
                                            .font(.system(size: 14)).foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "trash")
                                            .font(.system(size: 14)).foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            // ── Connected Printer ──────────────────────────
                            if let printer = vm.primaryPrinter {
                                SectionTitle(text: "Connected Printer").padding(.top, 8)
                                AppCard {
                                    infoRow("Name", value: printer.name)
                                    Divider().background(Color.dividerColor).padding(.leading, 16)
                                    infoRow("Connection", value: printer.connectionType)
                                    if !printer.hostName.isEmpty {
                                        Divider().background(Color.dividerColor).padding(.leading, 16)
                                        infoRow("Host", value: printer.hostName)
                                    }
                                    if !printer.model.isEmpty {
                                        Divider().background(Color.dividerColor).padding(.leading, 16)
                                        infoRow("Model", value: printer.model)
                                    }
                                }
                            }

                            // ── Support ────────────────────────────────────
                            SectionTitle(text: "Support").padding(.top, 8)
                            AppCard {
                                Button {
                                    if let scene = UIApplication.shared.connectedScenes
                                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                        SKStoreReviewController.requestReview(in: scene)
                                    }
                                } label: {
                                    settingsRow(icon: "star.fill", label: "Rate the App")
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.dividerColor).padding(.leading, 16)

                                Button {
                                    openMail(to: "contact@appchunks.com",
                                             subject: "HP Smart Printer - Issue Report",
                                             body: deviceInfoBody())
                                } label: {
                                    settingsRow(icon: "envelope.fill", label: "Contact Support")
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.dividerColor).padding(.leading, 16)

                                HStack {
                                    Label("Version", systemImage: "info.circle")
                                        .font(.system(size: 14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(appVersion)
                                        .font(.system(size: 14)).foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }

                            // ── Request a Feature ──────────────────────────
                            SectionTitle(text: "Request a Feature").padding(.top, 8)
                            AppCard {
                                Button {
                                    openMail(to: "i@appchunks.com",
                                             subject: "HP Smart Printer - Feature Request",
                                             body: featureRequestBody())
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(LinearGradient(
                                                    colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Suggest a Feature")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.textPrimary)
                                            Text("Tell us what you'd love to see next")
                                                .font(.system(size: 12))
                                                .foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            // ── Actions ────────────────────────────────────
                            PrimaryButton(title: "Print Test Page") { showTestPrintPicker = true }.padding(.top, 8)
                            SecondaryButton(title: "Reset to Defaults") { vm.resetSettings() }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.saveSettings() } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bg3)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cardBorder, lineWidth: 1))
                    }
                }
            }
            // ── All modifiers at NavigationView level ──────────────────
            .fullScreenCover(isPresented: $showPaywallFromSettings) {
                PaywallView(
                    onDismiss: { showPaywallFromSettings = false },
                    freePrintsRemaining: vm.freePrintsRemaining,
                    variant: activePaywallVariant
                )
                .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showTestPrintPicker) {
                TestPrintPickerSheet()
            }

            .confirmationDialog("Clear all print history?", isPresented: $showClearHistoryConfirm, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { vm.clearHistory() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            Text(value).font(.system(size: 14)).foregroundColor(.textSecondary).lineLimit(1)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func settingsRow(icon: String, label: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12)).foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func openMail(to address: String, subject: String, body: String) {
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(address)?subject=\(subEncoded)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func deviceInfoBody() -> String {
        let device  = UIDevice.current
        let version = appVersion
        return """


---
Device: \(device.model)
iOS: \(device.systemVersion)
App Version: \(version)
"""
    }

    private func featureRequestBody() -> String {
        let device  = UIDevice.current
        let version = appVersion
        return """
Hi,

I'd love to see this feature added:

[Describe your feature request here]

---
Device: \(device.model)
iOS: \(device.systemVersion)
App Version: \(version)
"""
    }
}

// MARK: - Subviews

struct DocumentPreview: View {
    var orientation: String
    var body: some View {
        let isLandscape = orientation == "Landscape"
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#9ca3af")).frame(width: 120, height: 14)
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#d1d5db")).frame(height: 8)
                    .frame(maxWidth: i % 2 == 0 ? .infinity : UIScreen.main.bounds.width * 0.5)
            }
            Spacer(minLength: 8)
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#d1d5db")).frame(height: 8)
                    .frame(maxWidth: i % 2 == 0 ? .infinity : UIScreen.main.bounds.width * 0.55)
            }
        }
        .padding(20)
        .frame(height: isLandscape ? 180 : 260)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            AppToggle(isOn: $isOn)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticService.shared.selection()
            isOn.toggle()
        }
    }
}

/// Separate row for haptics so toggling it always fires vibration while enabled,
/// and the last "off" toggle still gives feedback.
struct HapticsToggleRow: View {
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                .font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            AppToggle(isOn: $isOn)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if isOn { HapticService.shared.impact(.light) }
            isOn.toggle()
            if isOn { HapticService.shared.impact(.medium) }
        }
    }
}

struct SegmentRow: View {
    let label: String
    let options: [String]
    @Binding var selection: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 3) {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection = opt }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selection == opt ? .white : .textSecondary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(selection == opt ? Color.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                }
            }
            .padding(3)
            .background(Color.bg4)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct SegmentRowInt: View {
    let label: String
    let options: [Int]
    @Binding var selection: Int
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 3) {
                ForEach(options, id: \.self) { opt in
                    Button("\(opt)") { selection = opt }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selection == opt ? .white : .textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(selection == opt ? Color.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                }
            }
            .padding(3)
            .background(Color.bg4)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - Controls

struct AppToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.accent : Color.bg4)
                .frame(width: 46, height: 26)
                .overlay(Capsule().stroke(isOn ? Color.accent : Color.btnBorder, lineWidth: 1))
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(radius: 2)
                .padding(3)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

struct StepperControl: View {
    @Binding var value: Int
    let min: Int
    var body: some View {
        HStack(spacing: 12) {
            Button { if value > min { value -= 1 } } label: {
                Text("−").font(.system(size: 18)).foregroundColor(.textPrimary)
                    .frame(width: 30, height: 30).background(Color.bg4).clipShape(Circle())
                    .overlay(Circle().stroke(Color.btnBorder, lineWidth: 1))
            }
            Text("\(value)").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary).frame(minWidth: 24)
            Button { value += 1 } label: {
                Text("+").font(.system(size: 18)).foregroundColor(.textPrimary)
                    .frame(width: 30, height: 30).background(Color.bg4).clipShape(Circle())
                    .overlay(Circle().stroke(Color.btnBorder, lineWidth: 1))
            }
        }
    }
}

// MARK: - Rate App Sheet

struct RateAppSheet: View {
    @Binding var stars: Int
    var onDismiss: () -> Void
    @State private var submitted = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.bg4).frame(width: 36, height: 4)
                    .padding(.top, 12).padding(.bottom, 24)

                if submitted {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color(hex: "#0149E1").opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "heart.fill").font(.system(size: 34))
                                .foregroundColor(Color(hex: "#0149E1"))
                        }
                        Text("Thank You!").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
                        Text("Your feedback means the world to us.").font(.system(size: 15)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
                        Button("Close") { onDismiss() }
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(LinearGradient(colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 32).padding(.bottom, 40)
                } else {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Color(hex: "#0149E1").opacity(0.10)).frame(width: 72, height: 72)
                            Image(systemName: "star.fill").font(.system(size: 30))
                                .foregroundStyle(LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")], startPoint: .top, endPoint: .bottom))
                        }
                        Text("Enjoying the App?").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
                        Text("Tap a star to rate your experience").font(.system(size: 14)).foregroundColor(.textSecondary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { stars = i }
                                } label: {
                                    Image(systemName: i <= stars ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundStyle(i <= stars
                                            ? LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.bg4, Color.bg4], startPoint: .top, endPoint: .bottom))
                                        .scaleEffect(i <= stars ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: stars)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        if stars > 0 {
                            Button {
                                if stars >= 4 {
                                    let id = Bundle.main.bundleIdentifier ?? ""
                                    if let url = URL(string: "itms-apps://apps.apple.com/app/id\(id)?action=write-review") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                submitted = true
                            } label: {
                                Text(stars >= 4 ? "Rate on App Store" : "Submit Feedback")
                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(LinearGradient(colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .contentShape(Rectangle())
                            }
                            .transition(.opacity.combined(with: .scale))
                        }

                        Button("Not Now") { onDismiss() }
                            .font(.system(size: 14)).foregroundColor(.textSecondary)
                            .contentShape(Rectangle())
                    }
                    .padding(.horizontal, 32).padding(.bottom, 40)
                    .animation(.easeOut(duration: 0.3), value: stars)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .modifier(MediumSheetModifier())
    }
}

private struct MediumSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        } else {
            content
        }
    }
}
