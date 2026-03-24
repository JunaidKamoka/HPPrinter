import SwiftUI

struct SplashView: View {
    @Binding var isPresented: Bool

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var iconRotation: Double = -30
    @State private var ringScale1: CGFloat = 0.5
    @State private var ringScale2: CGFloat = 0.4
    @State private var ringScale3: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 15
    @State private var particlesVisible = false
    @State private var glowOpacity: Double = 0
    @State private var exitScale: CGFloat = 1
    @State private var exitOpacity: Double = 1

    // Particles
    private let particleCount = 16

    var body: some View {
        ZStack {
            // Background
            Color.bg.ignoresSafeArea()

            // Radial glow behind icon
            RadialGradient(
                colors: [Color.accent.opacity(glowOpacity * 0.3), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .ignoresSafeArea()

            // Floating particles
            ForEach(0..<particleCount, id: \.self) { i in
                particleDot(index: i)
            }

            // Main content
            VStack(spacing: 28) {
                Spacer()

                // Animated rings + icon
                ZStack {
                    // Ring 3 (outermost)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.accent.opacity(0.1), Color.accent2.opacity(0.05)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale3)
                        .opacity(ringOpacity * 0.5)

                    // Ring 2
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.accent.opacity(0.2), Color.accent2.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 155, height: 155)
                        .scaleEffect(ringScale2)
                        .opacity(ringOpacity * 0.7)

                    // Ring 1 (inner)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.accent.opacity(0.35), Color.accent2.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 115, height: 115)
                        .scaleEffect(ringScale1)
                        .opacity(ringOpacity)

                    // Icon container
                    ZStack {
                        // Glow circle
                        Circle()
                            .fill(Color.accent.opacity(0.12))
                            .frame(width: 90, height: 90)
                            .blur(radius: 8)

                        // Icon background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bg2, Color.bg3],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 82, height: 82)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.accent.opacity(0.5), Color.accent2.opacity(0.3)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: Color.accent.opacity(0.3), radius: 16, y: 4)

                        // Printer icon
                        Image(systemName: "printer.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accent, Color.accent2],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .rotationEffect(.degrees(iconRotation))
                }

                // App name
                VStack(spacing: 8) {
                    Text("HP Smart Printer")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.textPrimary, Color.textPrimary.opacity(0.85)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("Print & PDF Tools")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .opacity(subtitleOpacity)
                        .offset(y: subtitleOffset)
                }

                Spacer()

                // Bottom tagline
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11))
                    Text("100% Private — No Account Needed")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.textTertiary)
                .opacity(subtitleOpacity)
                .padding(.bottom, 50)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear {
            runAnimation()
        }
    }

    // MARK: - Particle

    private func particleDot(index: Int) -> some View {
        let angle = Double(index) / Double(particleCount) * 360
        let rad = angle * .pi / 180
        let distance: CGFloat = CGFloat.random(in: 100...180)
        let size: CGFloat = CGFloat([3, 4, 5, 6][index % 4])
        let colors: [Color] = [.accent, .accent2, .appBlue, .appGreen, .appAmber]

        return Circle()
            .fill(colors[index % colors.count].opacity(particlesVisible ? 0.6 : 0))
            .frame(width: size, height: size)
            .offset(
                x: cos(rad) * (particlesVisible ? distance : 30),
                y: sin(rad) * (particlesVisible ? distance : 30)
            )
            .blur(radius: particlesVisible ? 0 : 3)
            .animation(
                .easeOut(duration: 1.2)
                .delay(Double(index) * 0.04 + 0.3),
                value: particlesVisible
            )
    }

    // MARK: - Animation Sequence

    private func runAnimation() {
        // Phase 1: Icon appears (0.0s)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }

        // Phase 2: Rings expand (0.2s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
            ringScale1 = 1.0
            ringOpacity = 1.0
        }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.65).delay(0.3)) {
            ringScale2 = 1.0
        }
        withAnimation(.spring(response: 1.0, dampingFraction: 0.65).delay(0.4)) {
            ringScale3 = 1.0
        }

        // Phase 3: Glow + particles (0.4s)
        withAnimation(.easeInOut(duration: 0.8).delay(0.4)) {
            glowOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            particlesVisible = true
        }

        // Phase 4: Title slides up (0.6s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.6)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // Phase 5: Subtitle (0.8s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.8)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }

        // Phase 6: Exit (2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                exitScale = 1.15
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isPresented = false
            }
        }
    }
}
