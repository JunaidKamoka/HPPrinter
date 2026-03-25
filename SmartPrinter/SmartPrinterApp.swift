import SwiftUI

@main
struct SmartPrinterApp: App {
    @StateObject private var viewModel    = AppViewModel()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showRating     = false
    @State private var showSplash     = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)

                if showRating {
                    AppRatingView(isPresented: $showRating)
                        .transition(.opacity)
                        .zIndex(100)
                }

                if showOnboarding && !showSplash {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                        .zIndex(200)
                }

                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                        .zIndex(300)
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
            .onChange(of: scenePhase) { newPhase in
                guard !showOnboarding && !showSplash else { return }
                switch newPhase {
                case .active:
                    let rating = RatingService.shared
                    rating.recordLaunch()
                    if rating.shouldShowOnLaunch() {
                        rating.recordPromptShown()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showRating = true }
                        }
                    }
                case .inactive:
                    if !showRating {
                        let rating = RatingService.shared
                        if rating.shouldShowOnBackground() {
                            rating.recordPromptShown(isBackground: true)
                            withAnimation { showRating = true }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
