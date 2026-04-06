import SwiftUI
import SwiftData

@main
struct NordicSplitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [SplitRecord.self, PersonRecord.self])
        }
    }
}
