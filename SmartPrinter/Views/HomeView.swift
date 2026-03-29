import SwiftUI
import VisionKit

// MARK: - PDF Tool data for carousel
private struct PDFToolItem: Identifiable {
    let id = UUID()
    let sfSymbol: String
    let name: String
    let colorA: String
    let colorB: String
}

private let featuredTools: [PDFToolItem] = [
    .init(sfSymbol: "doc.on.doc.fill",                       name: "Merge PDF",   colorA: "#0149E1", colorB: "#3D7EFF"),
    .init(sfSymbol: "scissors",                              name: "Split PDF",   colorA: "#f472b6", colorB: "#fb7185"),
    .init(sfSymbol: "arrow.down.circle.fill",                name: "Compress",    colorA: "#34d399", colorB: "#059669"),
    .init(sfSymbol: "doc.text.fill",                         name: "To Word",     colorA: "#0149E1", colorB: "#6699FF"),
    .init(sfSymbol: "tablecells.fill",                       name: "To Excel",    colorA: "#4ade80", colorB: "#16a34a"),
    .init(sfSymbol: "text.viewfinder",                       name: "OCR PDF",     colorA: "#fbbf24", colorB: "#d97706"),
    .init(sfSymbol: "signature",                             name: "Sign PDF",    colorA: "#f87171", colorB: "#dc2626"),
    .init(sfSymbol: "lock.fill",                             name: "Protect",     colorA: "#0149E1", colorB: "#0141C5"),
    .init(sfSymbol: "rotate.right.fill",                     name: "Rotate",      colorA: "#fb923c", colorB: "#ea580c"),
    .init(sfSymbol: "wand.and.stars",                        name: "Edit PDF",    colorA: "#0149E1", colorB: "#3D7EFF"),
    .init(sfSymbol: "photo.fill",                            name: "To Image",    colorA: "#38bdf8", colorB: "#0284c7"),
    .init(sfSymbol: "rectangle.and.pencil.and.ellipsis",     name: "Annotate",    colorA: "#a3e635", colorB: "#65a30d"),
    .init(sfSymbol: "lock.open.fill",                        name: "Unlock PDF",  colorA: "#3D7EFF", colorB: "#0149E1"),
    .init(sfSymbol: "doc.badge.plus",                        name: "Add Pages",   colorA: "#67e8f9", colorB: "#0891b2"),
    .init(sfSymbol: "rectangle.portrait.and.arrow.right",    name: "Extract",     colorA: "#fda4af", colorB: "#be123c"),
]

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDocPicker        = false
    @State private var showPhotoPicker      = false
    @State private var showTestPrintPicker  = false
    @State private var showWritingPaper     = false
    @State private var showPDFTools         = false
    @State private var showDocumentScanner  = false
    @State private var showPaywallFromHome  = false
    @State private var activePaywallVariant = 0

    // Hero animation
    @State private var orbAnimate   = false
    @State private var pulseAnimate = false
    @State private var glowAnimate  = false
    @State private var numberPulse  = false
    @State private var numberGlow: CGFloat = 0.4

    // Carousel
    @State private var carouselIndex = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        heroSection
                            .padding(.horizontal)

                        carouselSection

                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Quick Print").padding(.horizontal)
                            quickActionsGrid.padding(.horizontal)
                        }

                        Button { showWritingPaper = true } label: { writingPaperRow }
                            .buttonStyle(.plain)
                            .padding(.horizontal)

                        if !vm.allKnownPrinters.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "Printer Status").padding(.horizontal)
                                printerStatusCard.padding(.horizontal)
                            }
                        }

                        if !vm.history.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "Recent Activity").padding(.horizontal)
                                recentActivityCard.padding(.horizontal)
                            }
                        }

                        if vm.allKnownPrinters.isEmpty && vm.history.isEmpty {
                            emptyState.padding(.horizontal)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("HP Smart Printer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activePaywallVariant = vm.paywallVariant
                        vm.nextPaywallVariant()
                        showPaywallFromHome = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .fill(
                                        subscriptionService.isPremium
                                        ? LinearGradient(colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.bg3, Color.bg3], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(
                                        subscriptionService.isPremium ? Color(hex: "#3D7EFF") : Color.cardBorder,
                                        lineWidth: 1
                                    ))
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(subscriptionService.isPremium ? .white : .textSecondary)
                            }
                            // free-tries badge
                            if !subscriptionService.isPremium {
                                Text("\(vm.freePrintsRemaining)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 14)
                                    .background(Color(hex: "#FF9500"))
                                    .clipShape(Circle())
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywallFromHome) {
                PaywallView(
                    onDismiss: { showPaywallFromHome = false },
                    freePrintsRemaining: vm.freePrintsRemaining,
                    variant: activePaywallVariant
                )
                .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showDocPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    let captured = url
                    vm.selectedFileURL = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        vm.printDirectly(url: captured)
                    }
                }
            }) { DocumentPicker { url in vm.handlePickedFile(url: url) } }
            .sheet(isPresented: $showPhotoPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    let captured = url
                    vm.selectedFileURL = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        vm.printDirectly(url: captured)
                    }
                }
            }) { PhotoPicker { url in vm.handlePickedFile(url: url) } }
            .sheet(isPresented: $showTestPrintPicker) { TestPrintPickerSheet() }
            .fullScreenCover(isPresented: $showWritingPaper) { WritingPaperView() }
            .fullScreenCover(isPresented: $showPDFTools) { PDFToolsView() }
            .fullScreenCover(isPresented: $showDocumentScanner) {
                DocumentScannerView { pdfURL in
                    showDocumentScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        vm.printFile(url: pdfURL, source: "Scan")
                    }
                } onCancel: {
                    showDocumentScanner = false
                }
                .ignoresSafeArea()
            }
            .onAppear {
                if vm.autoReconnect { vm.startScan() }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true))  { orbAnimate = true }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulseAnimate = true }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowAnimate = true }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { numberPulse = true }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { numberGlow = 1.0 }
            }
            .onReceive(Timer.publish(every: 2.4, on: .main, in: .common).autoconnect()) { _ in
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    carouselIndex = (carouselIndex + 1) % featuredTools.count
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero Section

    var heroSection: some View {
        let isLight = colorScheme == .light
        return ZStack(alignment: .topLeading) {
            // Base gradient — dark: deep navy; light: clean white/HP-blue tint
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(
                    colors: isLight
                        ? [Color(hex: "#F0F5FF"), Color(hex: "#E1EAFD"), Color(hex: "#FFFFFF")]
                        : [Color(hex: "#060D1F"), Color(hex: "#0B1530"), Color(hex: "#111E40")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            // Floating orb 1 — HP blue
            Circle()
                .fill(Color(hex: "#0149E1").opacity(isLight ? 0.14 : 0.32))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: orbAnimate ? 120 : 60, y: orbAnimate ? -55 : -95)

            // Floating orb 2 — lighter blue
            Circle()
                .fill(Color(hex: "#3D7EFF").opacity(isLight ? 0.08 : 0.18))
                .frame(width: 150, height: 150)
                .blur(radius: 44)
                .offset(x: orbAnimate ? -10 : 30, y: orbAnimate ? 100 : 60)

            // Floating orb 3 — accent2
            Circle()
                .fill(Color(hex: "#6699FF").opacity(isLight ? 0.06 : 0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 36)
                .offset(x: orbAnimate ? 270 : 230, y: orbAnimate ? 55 : 95)

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Badge
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("FREE · NO SIGN-UP REQUIRED")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.8)
                }
                .foregroundColor(isLight ? Color(hex: "#0149E1") : Color(hex: "#93BBFF"))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color(hex: "#0149E1").opacity(isLight ? 0.08 : 0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "#0149E1").opacity(isLight ? 0.25 : 0.35), lineWidth: 1))

                // Giant animated "99+ PDF Tools"
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ZStack {
                        // Glow halo behind number
                        Text("99+")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .blur(radius: numberPulse ? 18 : 10)
                            .opacity(numberPulse ? (isLight ? 0.30 : 0.60) : (isLight ? 0.15 : 0.30))
                            .scaleEffect(numberPulse ? 1.12 : 1.0)

                        // Main crisp text — light blue gradient dark, deep HP blue in light
                        Text("99+")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: isLight
                                    ? [Color(hex: "#0141C5"), Color(hex: "#0149E1"), Color(hex: "#1A5FE8"), Color(hex: "#3D7EFF")]
                                    : [Color(hex: "#ffffff"), Color(hex: "#D6E8FF"), Color(hex: "#93BBFF"), Color(hex: "#6699FF")],
                                startPoint: .top, endPoint: .bottom
                            ))
                    }
                    .scaleEffect(numberPulse ? 1.035 : 1.0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: numberPulse)

                    VStack(alignment: .leading, spacing: -2) {
                        Text("PDF")
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(isLight ? Color(hex: "#080E1F") : .white)
                        Text("Tools")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(isLight ? Color(hex: "#0149E1").opacity(0.55) : .white.opacity(0.5))
                    }
                    .padding(.bottom, 8)
                }

                // Feature chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["Merge", "Split", "OCR", "Sign", "Convert", "Compress", "Annotate"], id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isLight ? Color(hex: "#0149E1") : .white.opacity(0.65))
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(Color(hex: "#0149E1").opacity(isLight ? 0.08 : 0.07))
                                .clipShape(Capsule())
                        }
                    }
                }

                // CTA button
                Button { showPDFTools = true } label: {
                    HStack(spacing: 7) {
                        Text("Explore All Tools")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(LinearGradient(
                        colors: [Color(hex: "#0149E1"), Color(hex: "#3D7EFF")],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#0149E1").opacity(glowAnimate ? (isLight ? 0.35 : 0.60) : (isLight ? 0.18 : 0.30)),
                            radius: glowAnimate ? 18 : 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(22)
        }
        .frame(height: 268)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(LinearGradient(
                    colors: isLight
                        ? [Color(hex: "#0149E1").opacity(0.25), Color(hex: "#3D7EFF").opacity(0.10), Color.clear]
                        : [Color(hex: "#3D7EFF").opacity(0.40), Color(hex: "#6699FF").opacity(0.15), Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
    }

    // MARK: - Printer Connected Card

    var printerConnectedCard: some View {
        let connected = vm.primaryPrinter != nil
        let printer   = vm.primaryPrinter
        return HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(connected ? Color.appGreen.opacity(0.15) : Color.bg4)
                    .frame(width: 52, height: 52)
                if connected {
                    Circle()
                        .fill(Color.appGreen.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .scaleEffect(pulseAnimate ? 1.7 : 1.0)
                        .opacity(pulseAnimate ? 0 : 0.8)
                }
                Image(systemName: "printer.fill")
                    .font(.system(size: 22))
                    .foregroundColor(connected ? .appGreen : .textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                if connected, let p = printer {
                    HStack(spacing: 5) {
                        Circle().fill(Color.appGreen).frame(width: 7, height: 7)
                        Text("Connected")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appGreen)
                    }
                    Text(p.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    Text("via \(p.connectionType)\(p.hostName.isEmpty ? "" : " · \(p.hostName)")")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                } else {
                    Text("No Printer Found")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Tap Find to discover printers on your network")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if connected {
                BadgeView(text: "Ready", fg: .appGreen, bg: .greenBg)
            } else {
                Button { vm.startScan() } label: {
                    Label("Find", systemImage: "wifi")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accent)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.accent.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.accent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(
            connected ? Color.appGreen.opacity(0.3) : Color.cardBorder,
            lineWidth: 1
        ))
    }

    // MARK: - PDF Tools Carousel

    var carouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(text: "PDF Tools")
                Spacer()
                Button { showPDFTools = true } label: {
                    Text("See All 99+")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accent)
                }
            }
            .padding(.horizontal)

            // Scrolling tool tiles
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(featuredTools.enumerated()), id: \.element.id) { i, tool in
                            ToolCarouselCard(tool: tool, isHighlighted: i == carouselIndex)
                                .id(i)
                                .onTapGesture { showPDFTools = true }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .onChange(of: carouselIndex) { idx in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        proxy.scrollTo(idx, anchor: .center)
                    }
                }
            }

            // Dot indicators
            HStack(spacing: 5) {
                ForEach(0..<featuredTools.count, id: \.self) { i in
                    Capsule()
                        .fill(i == carouselIndex ? Color.accent : Color.bg4)
                        .frame(width: i == carouselIndex ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: carouselIndex)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }

    // MARK: - Quick Actions Grid

    var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            QuickActionButton(icon: "📂", title: "Print File",       subtitle: "PDF, DOCX, JPG...")      { showDocPicker = true }
            QuickActionButton(icon: "🖼️", title: "Print Photo",    subtitle: "Camera roll")             { showPhotoPicker = true }
            QuickActionButton(icon: "📷", title: "Scan Document",  subtitle: "Camera → PDF → Print")    { showDocumentScanner = true }
            QuickActionButton(icon: "🖨️", title: "Test Print",     subtitle: "B&W, Color, Label...")    { showTestPrintPicker = true }
        }
    }

    // MARK: - Writing Paper Row

    var writingPaperRow: some View {
        HStack(spacing: 12) {
            Text("📝").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text("Writing Paper Generator")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("Grid, dot, lined — generate & print")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accent.opacity(0.22), lineWidth: 1))
    }

    // MARK: - Printer Status Card

    var printerStatusCard: some View {
        AppCard {
            let printers = vm.allKnownPrinters
            ForEach(Array(printers.enumerated()), id: \.element.id) { idx, printer in
                PrinterStatusRow(printer: printer)
                if idx < printers.count - 1 {
                    Divider().background(Color.dividerColor).padding(.leading, 64)
                }
            }
        }
    }

    // MARK: - Recent Activity Card

    var recentActivityCard: some View {
        AppCard {
            let recent = Array(vm.history.prefix(5))
            ForEach(Array(recent.enumerated()), id: \.element.id) { idx, job in
                RecentActivityRow(job: job)
                if idx < recent.count - 1 {
                    Divider().background(Color.dividerColor).padding(.leading, 64)
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Text("🖨️").font(.system(size: 48))
            Text("Get Started")
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.textPrimary)
            Text("Find a printer on your network, then pick a file to print.")
                .font(.system(size: 14)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Find Printers") { vm.startScan() }.padding(.top, 8)
        }
        .padding(24)
    }
}

// MARK: - Tool Carousel Card

private struct ToolCarouselCard: View {
    let tool: PDFToolItem
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(hex: tool.colorA), Color(hex: tool.colorB)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: isHighlighted ? 62 : 54, height: isHighlighted ? 62 : 54)
                    .shadow(color: Color(hex: tool.colorA).opacity(isHighlighted ? 0.55 : 0.25),
                            radius: isHighlighted ? 12 : 6, x: 0, y: 4)

                Image(systemName: tool.sfSymbol)
                    .font(.system(size: isHighlighted ? 26 : 22, weight: .medium))
                    .foregroundColor(.white)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHighlighted)

            Text(tool.name)
                .font(.system(size: 11, weight: isHighlighted ? .semibold : .medium))
                .foregroundColor(isHighlighted ? .textPrimary : .textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 78)
        }
        .frame(width: 94)
        .padding(.vertical, 16)
        .background(isHighlighted ? Color.bg3 : Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isHighlighted ? Color(hex: tool.colorA).opacity(0.45) : Color.cardBorder,
                    lineWidth: isHighlighted ? 1.5 : 1
                )
        )
        .scaleEffect(isHighlighted ? 1.06 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHighlighted)
    }
}

// MARK: - Subviews (kept from original)

struct HeroStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(icon).font(.system(size: 24))
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct PrinterStatusRow: View {
    let printer: Printer
    var badgeColor: Color {
        switch printer.status { case .online: return .appGreen; case .warning: return .appAmber; case .offline: return .textTertiary }
    }
    var badgeBg: Color {
        switch printer.status { case .online: return .greenBg; case .warning: return .amberBg; case .offline: return .bg4 }
    }
    var statusDescription: String {
        switch printer.status {
        case .online:  return "Ready · \(printer.connectionType)"
        case .warning: return "Warning · Check printer"
        case .offline: return "Offline"
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(printer.status == .online ? Color.greenBg : printer.status == .warning ? Color.amberBg : Color.bg4)
                    .frame(width: 36, height: 36)
                Text(printer.status.icon).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(printer.name).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary).lineLimit(1)
                Text(statusDescription).font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            BadgeView(text: printer.status.label, fg: badgeColor, bg: badgeBg)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct RecentActivityRow: View {
    let job: PrintJob
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(job.status == .done ? Color.blueBg : job.status == .failed ? Color.redBg : Color.amberBg)
                    .frame(width: 36, height: 36)
                Text(job.fileIcon).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(job.fileName).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary).lineLimit(1)
                Text("\(job.pageCount) pages · \(job.colorMode) · \(job.formattedDate)")
                    .font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            if job.status == .done       { BadgeView(text: "Done",     fg: .appGreen, bg: .greenBg) }
            else if job.status == .failed { BadgeView(text: "Failed",   fg: .appRed,   bg: .redBg)   }
            else                          { BadgeView(text: "Printing", fg: .appAmber, bg: .amberBg) }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct TestPrintPickerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Select a test print to send to your printer via the native print sheet.")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(AppViewModel.testPrints) { tp in
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { vm.sendTestPrint(tp) }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12).fill(Color.bg3).frame(width: 48, height: 48)
                                        Text(tp.icon).font(.system(size: 22))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(tp.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                                        Text(tp.subtitle).font(.system(size: 12)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "printer.fill").font(.system(size: 16)).foregroundColor(.accent)
                                }
                                .padding(14)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.isDownloadingTestPrint)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Test Prints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accent)
                }
            }
        }
    }
}
