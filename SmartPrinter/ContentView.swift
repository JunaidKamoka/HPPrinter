import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                FormsView()
                    .tabItem {
                        Label("Forms", systemImage: "doc.text.fill")
                    }
                    .tag(1)

                PrintablesView()
                    .tabItem {
                        Label("Printables", systemImage: "rectangle.grid.2x2.fill")
                    }
                    .tag(2)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(Color.accent2)

            // Toast overlay
            if vm.showToast {
                VStack {
                    ToastView(message: vm.toastMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 56)
                    Spacer()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showToast)
                .allowsHitTesting(false)
            }

            // Rating overlay (triggered after successful actions)
            if vm.showRating {
                AppRatingView(isPresented: $vm.showRating)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
}
