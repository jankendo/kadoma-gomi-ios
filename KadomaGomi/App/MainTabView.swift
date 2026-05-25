import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            CollectionCalendarView()
                .tabItem { Label("カレンダー", systemImage: "calendar") }

            SearchView()
                .tabItem { Label("分別検索", systemImage: "magnifyingglass") }

            BulkyWasteView()
                .tabItem { Label("粗大ごみ", systemImage: "sofa.fill") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
    }
}

