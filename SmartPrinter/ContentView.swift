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

                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "wifi")
                    }
                    .tag(1)

                QueueView()
                    .tabItem {
                        Label("Queue", systemImage: "tray.full.fill")
                    }
                    .badge(vm.queue.count)
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
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
        }
    }
}
