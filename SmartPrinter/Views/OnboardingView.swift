import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var animateContent = false
    @Environment(\.colorScheme) private var colorScheme

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Background gradient shifts per page
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage = totalPages - 1
                                animateContent = false
                            }
                            triggerAnimate()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.bg3)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(height: 44)

                Spacer()

                // Page content
                Group {
                    switch currentPage {
                    case 0: page1_PrintPower
                    case 1: page2_PDFTools
                    case 2: page3_Discovery
                    case 3: page4_SmartQueue
                    case 4: page5_RateReview
                    default: EmptyView()
                    }
                }
                .id(currentPage)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Page indicator + button
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.accent : Color.bg4)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if currentPage < totalPages - 1 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                currentPage += 1
                                animateContent = false
                            }
                            triggerAnimate()
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                                .font(.system(size: 17, weight: .bold))
                            if currentPage < totalPages - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.accent, Color.accent2],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.accent.opacity(0.4), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { triggerAnimate() }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 && currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            currentPage += 1
                            animateContent = false
                        }
                        triggerAnimate()
                    } else if value.translation.width > 40 && currentPage > 0 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            currentPage -= 1
                            animateContent = false
                        }
                        triggerAnimate()
                    }
                }
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let isDark = colorScheme == .dark
        let colors: [Color] = {
            switch currentPage {
            case 0: // Purple/printer
                return isDark
                    ? [Color(hex: "#0a0a1a"), Color(hex: "#0f0f2a"), Color(hex: "#0a0a0f")]
                    : [Color(hex: "#f8f7ff"), Color(hex: "#ede9ff"), Color(hex: "#ffffff")]
            case 1: // Blue/PDF tools
                return isDark
                    ? [Color(hex: "#0a0f1a"), Color(hex: "#0a1a2a"), Color(hex: "#0a0a0f")]
                    : [Color(hex: "#f5f8ff"), Color(hex: "#e8f0ff"), Color(hex: "#ffffff")]
            case 2: // Green/discovery
                return isDark
                    ? [Color(hex: "#0a1a0f"), Color(hex: "#0a2a1a"), Color(hex: "#0a0a0f")]
                    : [Color(hex: "#f5fff7"), Color(hex: "#e8f5ec"), Color(hex: "#ffffff")]
            case 3: // Amber/queue
                return isDark
                    ? [Color(hex: "#1a0f0a"), Color(hex: "#2a1a0a"), Color(hex: "#0a0a0f")]
                    : [Color(hex: "#fffcf5"), Color(hex: "#fff3e0"), Color(hex: "#ffffff")]
            case 4: // Pink/review
                return isDark
                    ? [Color(hex: "#1a0a1a"), Color(hex: "#2a0a2a"), Color(hex: "#0a0a0f")]
                    : [Color(hex: "#fff7ff"), Color(hex: "#f5e8ff"), Color(hex: "#ffffff")]
            default:
                return [Color.bg, Color.bg2, Color.bg]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Page 1: Print Power

    private var page1_PrintPower: some View {
        VStack(spacing: 24) {
            // Animated printer with radiating rings
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(Color.accent.opacity(animateContent ? 0.0 : 0.3), lineWidth: 2)
                        .frame(width: animateContent ? CGFloat(200 + ring * 50) : 80, height: animateContent ? CGFloat(200 + ring * 50) : 80)
                        .animation(
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(ring) * 0.4),
                            value: animateContent
                        )
                }

                // Printer icon
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(Color.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "printer.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accent)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateContent)
                }
            }
            .frame(height: 220)

            VStack(spacing: 12) {
                Text("Print Anything\nin Seconds")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

                Text("One tap to print documents, photos & files\nto any AirPrint printer on your Wi-Fi")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateContent)
            }

            // Supported file types
            HStack(spacing: 12) {
                fileBadge("PDF", color: .appRed)
                fileBadge("DOCX", color: .appBlue)
                fileBadge("XLSX", color: .appGreen)
                fileBadge("IMG", color: .appAmber)
                fileBadge("TXT", color: .accent2)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 2: PDF Tools

    private var page2_PDFTools: some View {
        VStack(spacing: 24) {
            // Animated tool grid
            ZStack {
                // Orbiting icons
                let tools: [(String, Color, Double)] = [
                    ("doc.on.doc.fill", .accent, 0),
                    ("scissors", .appBlue, 45),
                    ("lock.fill", .appGreen, 90),
                    ("signature", .appAmber, 135),
                    ("text.viewfinder", .appRed, 180),
                    ("photo.fill", .accent2, 225),
                    ("wrench.fill", .appBlue, 270),
                    ("paintbrush.fill", .appGreen, 315),
                ]

                ForEach(0..<tools.count, id: \.self) { i in
                    let (icon, color, angle) = tools[i]
                    let radians = (angle + (animateContent ? 360 : 0)) * .pi / 180
                    let radius: CGFloat = 85

                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 42, height: 42)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
                    .animation(
                        .linear(duration: 20)
                        .repeatForever(autoreverses: false),
                        value: animateContent
                    )
                }

                // Center badge
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.2))
                        .frame(width: 80, height: 80)
                    VStack(spacing: 2) {
                        Text("99+")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.accent)
                        Text("Tools")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accent2)
                    }
                    .scaleEffect(animateContent ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: animateContent)
                }
            }
            .frame(height: 220)

            VStack(spacing: 12) {
                Text("99+ PDF Tools\nAll in One App")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

                Text("Merge, split, compress, convert, sign,\nOCR, watermark, encrypt & so much more")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateContent)
            }

            // Category pills
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    categoryPill("Convert", "arrow.triangle.2.circlepath", .accent)
                    categoryPill("Edit", "pencil.tip.crop.circle", .appGreen)
                    categoryPill("Secure", "lock.shield.fill", .appAmber)
                }
                HStack(spacing: 8) {
                    categoryPill("OCR", "text.viewfinder", .appBlue)
                    categoryPill("Forms", "list.clipboard.fill", .accent2)
                    categoryPill("Extract", "tray.and.arrow.up.fill", .appRed)
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 3: Printer Discovery

    private var page3_Discovery: some View {
        VStack(spacing: 24) {
            // Animated radar
            ZStack {
                // Radar sweep
                ForEach(0..<4, id: \.self) { ring in
                    Circle()
                        .stroke(Color.appGreen.opacity(0.08 + Double(ring) * 0.04), lineWidth: 1.5)
                        .frame(
                            width: CGFloat(60 + ring * 45),
                            height: CGFloat(60 + ring * 45)
                        )
                }

                // Radar sweep line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appGreen.opacity(0.5), Color.clear],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(width: 2, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(animateContent ? 360 : 0))
                    .animation(
                        .linear(duration: 3)
                        .repeatForever(autoreverses: false),
                        value: animateContent
                    )

                // Discovered printers popping in
                let printers: [(String, CGFloat, CGFloat, Double)] = [
                    ("HP", -55, -40, 0.5),
                    ("Canon", 60, -25, 0.9),
                    ("Epson", -35, 55, 1.3),
                    ("Brother", 50, 50, 1.7),
                    ("Samsung", -65, 10, 2.1),
                ]

                ForEach(0..<printers.count, id: \.self) { i in
                    let (name, x, y, delay) = printers[i]
                    printerDot(name: name)
                        .offset(x: x, y: y)
                        .scaleEffect(animateContent ? 1.0 : 0.0)
                        .opacity(animateContent ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(delay),
                            value: animateContent
                        )
                }

                // Center phone
                ZStack {
                    Circle()
                        .fill(Color.appGreen.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "iphone")
                        .font(.system(size: 22))
                        .foregroundColor(.appGreen)
                }
            }
            .frame(height: 220)

            VStack(spacing: 12) {
                Text("Auto-Discover\nYour Printers")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

                Text("Instantly finds all AirPrint printers\non your Wi-Fi network — zero setup needed")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateContent)
            }

            // Brand logos
            HStack(spacing: 14) {
                brandPill("HP")
                brandPill("Canon")
                brandPill("Epson")
                brandPill("Brother")
                brandPill("50+")
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 4: Smart Queue & History

    private var page4_SmartQueue: some View {
        VStack(spacing: 24) {
            // Animated queue cards
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let colors: [Color] = [.appBlue, .appGreen, .appAmber, .accent]
                    let icons = ["doc.fill", "photo.fill", "tablecells.fill", "doc.richtext.fill"]
                    let names = ["Report.pdf", "Photo.jpg", "Data.xlsx", "Resume.docx"]
                    let yBase: CGFloat = CGFloat(i) * 52 - 78

                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors[i].opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: icons[i])
                                .font(.system(size: 15))
                                .foregroundColor(colors[i])
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(names[i])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.bg4)
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colors[i])
                                        .frame(
                                            width: animateContent
                                                ? geo.size.width * CGFloat([1.0, 0.75, 0.45, 0.2][i])
                                                : 0,
                                            height: 6
                                        )
                                        .animation(
                                            .easeInOut(duration: 1.2)
                                            .delay(Double(i) * 0.25 + 0.3),
                                            value: animateContent
                                        )
                                }
                            }
                            .frame(height: 6)
                        }

                        Text(i == 0 ? "Done" : i == 1 ? "75%" : i == 2 ? "Queued" : "Next")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(i == 0 ? .appGreen : colors[i])
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
                    .frame(width: 260)
                    .offset(y: yBase)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(i) * 0.15),
                        value: animateContent
                    )
                }
            }
            .frame(height: 220)

            VStack(spacing: 12) {
                Text("Smart Queue\n& Print History")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

                Text("Queue files for batch printing & track\nevery job with detailed statistics")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateContent)
            }

            // Stats row
            HStack(spacing: 20) {
                statBadge(value: "∞", label: "Pages", color: .accent)
                statBadge(value: "100%", label: "Private", color: .appGreen)
                statBadge(value: "0", label: "Accounts", color: .appAmber)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 5: Rate & Review

    private var page5_RateReview: some View {
        VStack(spacing: 20) {
            // Animated stars
            ZStack {
                // Sparkle particles
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30
                    let rad = angle * .pi / 180
                    let dist: CGFloat = animateContent ? CGFloat.random(in: 70...120) : 30

                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 8...14)))
                        .foregroundColor(
                            [Color.accent, .accent2, .appAmber, .appGreen, .appBlue][i % 5]
                                .opacity(animateContent ? 0.7 : 0)
                        )
                        .offset(
                            x: cos(rad) * dist,
                            y: sin(rad) * dist
                        )
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                            value: animateContent
                        )
                }

                // Stars row
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.appAmber)
                            .scaleEffect(animateContent ? 1.0 : 0.0)
                            .rotationEffect(.degrees(animateContent ? 0 : -180))
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.5)
                                .delay(Double(i) * 0.12 + 0.2),
                                value: animateContent
                            )
                    }
                }
            }
            .frame(height: 180)

            VStack(spacing: 12) {
                Text("Love HP Smart Printer?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: animateContent)

                Text("Your rating helps us improve & reach\nmore people who need easy printing!")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.75), value: animateContent)
            }

            // Rate now button
            Button {
                requestReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 15))
                    Text("Rate Us on the App Store")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.appAmber, Color(hex: "#f59e0b")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.appAmber.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.horizontal, 32)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.9), value: animateContent)

            // Highlights
            HStack(spacing: 16) {
                miniHighlight(icon: "printer.fill", text: "AirPrint")
                miniHighlight(icon: "doc.fill", text: "99+ Tools")
                miniHighlight(icon: "lock.shield.fill", text: "Private")
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(1.0), value: animateContent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Subviews

    private func fileBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func categoryPill(_ text: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func printerDot(name: String) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "printer.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.appGreen)
            }
            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
    }

    private func brandPill(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.bg3)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(width: 72, height: 56)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func miniHighlight(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.textSecondary)
    }

    // MARK: - Actions

    private func triggerAnimate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateContent = true
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
