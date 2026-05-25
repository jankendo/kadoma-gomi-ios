import Foundation

@MainActor
final class MasterStore: ObservableObject {
    @Published private(set) var master: MunicipalityMaster
    @Published var settings: UserSettings
    @Published private(set) var syncMessage: String?
    @Published private(set) var isSyncing = false

    private let calendarService = CalendarGenerateService()
    private static let settingsKey = "kadoma.userSettings.v1"
    private static let masterKey = "kadoma.master.v1"

    init() {
        let bundled = Self.loadBundledMaster()
        self.master = Self.loadCachedMaster() ?? bundled
        self.settings = Self.loadSettings(key: Self.settingsKey) ?? UserSettings()
        if !master.areas.contains(where: { $0.id == settings.areaId }) {
            self.settings.areaId = master.defaultAreaId
        }
    }

    var currentArea: CollectionArea? {
        master.areas.first { $0.id == settings.areaId }
    }

    func category(for id: String) -> WasteCategory? {
        master.categories.first { $0.id == id }
    }

    func events(on date: Date) -> [CollectionEvent] {
        summaryProvider().events(on: date)
    }

    func events(from start: Date, days: Int) -> [CollectionEvent] {
        summaryProvider().events(from: start, days: days)
    }

    func nextEvents(limit: Int = 5) -> [CollectionEvent] {
        Array(events(from: .now, days: 45).filter { $0.date >= Calendar.kadoma.startOfDay(for: .now) }.prefix(limit))
    }

    func collectionSummary(referenceDate: Date = .now, nextLimit: Int = 7) -> AreaCollectionSummary {
        summaryProvider().areaSummary(referenceDate: referenceDate, nextLimit: nextLimit)
    }

    func searchItems(query: String) -> [WasteItem] {
        WasteSearchService(items: master.itemDictionary, categories: master.categories).search(query)
    }

    func resolveAndSaveAddress(_ address: String) -> Bool {
        guard let areaId = AddressResolver().resolveArea(addressText: address, master: master) else {
            return false
        }
        settings.addressText = address
        settings.areaId = areaId
        saveSettings()
        return true
    }

    func applyDefaultDistrictPreset() {
        settings.addressText = "大倉町1-20"
        settings.areaId = "A"
        saveSettings()
    }

    func setArea(_ areaId: String, addressText: String? = nil) {
        guard master.areas.contains(where: { $0.id == areaId }) else { return }
        settings.areaId = areaId
        if let addressText {
            settings.addressText = addressText
        }
        saveSettings()
    }

    func markOnboardingCompleted() {
        settings.hasCompletedOnboarding = true
        saveSettings()
    }

    func resetOnboarding() {
        settings.hasCompletedOnboarding = false
        saveSettings()
    }

    func setCategoryNotificationEnabled(_ enabled: Bool, categoryId: String) {
        settings.categoryNotificationOverrides[categoryId] = enabled
        saveSettings()
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    func refreshMaster() async {
        guard let manifestURL = URL(string: settings.remoteManifestURL) else {
            syncMessage = "マスタURLが正しくありません"
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let result = try await MasterSyncService().fetchRemoteMaster(manifestURL: manifestURL, currentVersion: master.version)
            settings.lastMasterCheckAt = KadomaDateFormatter.timestamp.string(from: .now)
            switch result {
            case .upToDate(let message):
                syncMessage = message
                saveSettings()
            case .updated(let remoteMaster, let message):
                master = remoteMaster
                cacheMaster(remoteMaster)
                settings.lastSuccessfulMasterRefreshAt = KadomaDateFormatter.timestamp.string(from: .now)
                saveSettings()
                syncMessage = message
                await rescheduleNotifications()
            }
        } catch {
            settings.lastMasterCheckAt = KadomaDateFormatter.timestamp.string(from: .now)
            saveSettings()
            syncMessage = "更新確認に失敗しました: \(error.localizedDescription)"
        }
    }

    func rescheduleNotifications() async {
        let upcoming = events(from: .now, days: 60)
        do {
            try await NotificationService().reschedule(
                events: upcoming,
                categories: master.categories,
                settings: settings
            )
            syncMessage = "通知を直近60日分で再設定しました"
        } catch {
            syncMessage = "通知設定に失敗しました: \(error.localizedDescription)"
        }
    }

    func notificationPreviews(limit: Int = 8) -> [NotificationPreview] {
        NotificationService().previews(
            events: events(from: .now, days: 60),
            categories: master.categories,
            settings: settings,
            limit: limit
        )
    }

    private func summaryProvider() -> GarbageSummaryProvider {
        GarbageSummaryProvider(master: master, settings: settings, calendarService: calendarService)
    }

    private func cacheMaster(_ master: MunicipalityMaster) {
        guard let data = try? JSONEncoder().encode(master) else { return }
        UserDefaults.standard.set(data, forKey: Self.masterKey)
    }

    private static func loadSettings(key: String) -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }

    private static func loadCachedMaster() -> MunicipalityMaster? {
        guard let data = UserDefaults.standard.data(forKey: masterKey) else { return nil }
        return try? JSONDecoder().decode(MunicipalityMaster.self, from: data)
    }

    private static func loadBundledMaster() -> MunicipalityMaster {
        guard
            let url = Bundle.main.url(forResource: "initial_master_27223_2026", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let master = try? JSONDecoder().decode(MunicipalityMaster.self, from: data)
        else {
            preconditionFailure("Bundled master JSON is missing or invalid.")
        }
        return master
    }
}
