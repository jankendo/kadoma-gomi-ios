import SwiftData
import SwiftUI

@main
struct KadomaGomiApp: App {
    @StateObject private var store = MasterStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
        }
        .modelContainer(for: [
            UserPreference.self,
            CachedCollectionEvent.self
        ])
    }
}

