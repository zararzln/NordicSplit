import SwiftUI

struct ContentView: View {
    @State private var container = AppContainer()

    var body: some View {
        TabView(selection: $container.selectedTab) {
            SplitView()
                .tabItem { Label("Split", systemImage: "equal.circle.fill") }
                .tag(AppContainer.Tab.split)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppContainer.Tab.history)
        }
        .environment(container)
    }
}
