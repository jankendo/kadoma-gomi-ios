import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                openSearch: { selectedTab = .search },
                openGuide: { selectedTab = .guide },
                openCalendar: { selectedTab = .calendar },
                openSettings: { selectedTab = .settings }
            )
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)

            SearchView()
                .tabItem { Label("ごみ検索", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            WasteGuideView()
                .tabItem { Label("ごみ分別", systemImage: "trash.fill") }
                .tag(AppTab.guide)

            CollectionCalendarView()
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(AppTab.calendar)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(AppColor.appTint)
        .fullScreenCover(
            isPresented: Binding(
                get: { !store.settings.hasCompletedOnboarding },
                set: { if !$0 { store.markOnboardingCompleted() } }
            )
        ) {
            OnboardingView(
                complete: {
                    store.applyDefaultDistrictPreset()
                    store.markOnboardingCompleted()
                    selectedTab = .home
                },
                skip: {
                    store.markOnboardingCompleted()
                    selectedTab = .home
                }
            )
        }
    }
}
