import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: MasterStore
    @Environment(\.openURL) private var openURL
    @AppStorage("kadoma.developerModeEnabled") private var developerModeEnabled = false

    @State private var addressText = ""
    @State private var addressMessage: SettingsMessage?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var appInfoTapCount = 0
    @State private var developerModeMessage: SettingsMessage?

    private var showsDeveloperTools: Bool {
        developerModeEnabled || Self.isDebugBuild
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                DistrictSettingsCard(
                    addressText: $addressText,
                    currentAddress: store.settings.addressText,
                    currentAreaName: store.currentArea?.name ?? "\(store.settings.areaId)地区",
                    areas: store.master.areas,
                    selectedAreaId: store.settings.areaId,
                    message: addressMessage,
                    save: saveAddress,
                    applyPreset: applyPreset,
                    selectArea: selectArea
                )

                NotificationSettingsCard(
                    status: notificationStatus,
                    settings: $store.settings,
                    categories: store.master.categories.filter { $0.id != "recycle_law" && $0.id != "hazardous_note" },
                    categoryProvider: store.category(for:),
                    previews: store.notificationPreviews(limit: 8),
                    saveSettings: store.saveSettings,
                    setCategory: { enabled, categoryId in
                        store.setCategoryNotificationEnabled(enabled, categoryId: categoryId)
                    },
                    requestPermission: requestNotifications,
                    openSystemSettings: openSystemSettings
                )

                DataUpdateSettingsCard(store: store)
                DisplayAccessibilityCard()
                OfficialLinksCard(pages: store.master.sourcePages)
                HelpAndAppInfoCard(
                    resetOnboarding: {
                        store.resetOnboarding()
                    },
                    versionTapped: handleVersionTap
                )
                if let developerModeMessage, !showsDeveloperTools {
                    InlineSettingsMessage(message: developerModeMessage)
                }
                if showsDeveloperTools {
                    DeveloperSettingsEntryCard(store: store, isDebugBuild: Self.isDebugBuild)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                addressText = store.settings.addressText
                await refreshNotificationStatus()
            }
        }
    }

    private func saveAddress() {
        let ok = store.resolveAndSaveAddress(addressText)
        addressMessage = ok
            ? SettingsMessage(kind: .success, text: "\(store.currentArea?.name ?? store.settings.areaId)として保存しました。通知とカレンダーはこの地区で表示されます。")
            : SettingsMessage(kind: .error, text: "地区を判定できませんでした。例: 大倉町1-20 のように町名を含めて入力してください。")
        if ok {
            Task { await store.rescheduleNotifications() }
        }
    }

    private func applyPreset() {
        store.applyDefaultDistrictPreset()
        addressText = store.settings.addressText
        addressMessage = SettingsMessage(kind: .success, text: "門真市 大倉町1-20 / A地区を設定しました。")
        Task { await store.rescheduleNotifications() }
    }

    private func selectArea(_ areaId: String) {
        guard let area = store.master.areas.first(where: { $0.id == areaId }) else { return }
        let addressLabel = area.id == "A" ? "大倉町1-20" : "\(area.name) 手動選択"
        store.setArea(area.id, addressText: addressLabel)
        addressText = store.settings.addressText
        addressMessage = SettingsMessage(kind: .success, text: "\(area.name)を設定しました。地区変更後は通知を再設定します。")
        Task { await store.rescheduleNotifications() }
    }

    private func requestNotifications() {
        Task {
            await store.rescheduleNotifications()
            await refreshNotificationStatus()
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    private func handleVersionTap() {
        appInfoTapCount += 1
        guard !showsDeveloperTools else { return }
        if appInfoTapCount >= 7 {
            developerModeEnabled = true
            developerModeMessage = SettingsMessage(kind: .success, text: "開発者用機能を表示しました。通知テストや詳細ログを確認できます。")
        } else if appInfoTapCount >= 4 {
            let remain = 7 - appInfoTapCount
            developerModeMessage = SettingsMessage(kind: .success, text: "開発者用機能を表示するには、あと\(remain)回タップします。")
        }
    }
}

private struct SettingsMessage: Equatable {
    enum Kind {
        case success
        case error
    }

    let kind: Kind
    let text: String
}

private struct DistrictSettingsCard: View {
    @Binding var addressText: String
    let currentAddress: String
    let currentAreaName: String
    let areas: [CollectionArea]
    let selectedAreaId: String
    let message: SettingsMessage?
    let save: () -> Void
    let applyPreset: () -> Void
    let selectArea: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("お住まいの地区", subtitle: "地区を間違えると収集日が変わります", systemImage: AppIcon.district)

            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.area)
                    .font(.title2.weight(.semibold))
                    .frame(width: 50, height: 50)
                    .background(AppColor.backgroundTop, in: Circle())
                    .foregroundStyle(AppColor.appTint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("現在の設定")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.secondaryText)
                    Text("門真市 \(currentAddress)")
                        .font(AppTypography.cardTitle)
                    Text(currentAreaName)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(AppColor.appTint)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("地区を選ぶ")
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.secondaryText)
                Picker("地区を選ぶ", selection: Binding(
                    get: { selectedAreaId },
                    set: { selectArea($0) }
                )) {
                    ForEach(areas) { area in
                        Text("\(area.name)（\(area.towns.prefix(3).map(\.townName).joined(separator: "・"))）")
                            .tag(area.id)
                    }
                }
                .pickerStyle(.menu)
                .minimumTapTarget()
                Text("番地で地区が分かれる町名は、住所入力で判定できない場合があります。その場合は公式ページを確認して地区を選んでください。")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("例: 大倉町1-20", text: $addressText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .minimumTapTarget()
                .accessibilityLabel("住所入力")
                .accessibilityHint("町名を含めて入力してください。大倉町はA地区です。")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    districtButtons
                }
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    districtButtons
                }
            }

            Text("初期版ではGPSを使いません。住所は端末内の設定として保存されます。")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.secondaryText)

            if let message {
                InlineSettingsMessage(message: message)
            }
        }
        .appCard()
    }

    private var districtButtons: some View {
        Group {
            Button(action: applyPreset) {
                Label("大倉町1-20を使う", systemImage: AppIcon.today)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.appTint)

            Button(action: save) {
                Label("入力住所で保存", systemImage: AppIcon.success)
                    .frame(maxWidth: .infinity)
            }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
    }
}

private struct NotificationSettingsCard: View {
    let status: UNAuthorizationStatus
    @Binding var settings: UserSettings
    let categories: [WasteCategory]
    let categoryProvider: (String) -> WasteCategory?
    let previews: [NotificationPreview]
    let saveSettings: () -> Void
    let setCategory: (Bool, String) -> Void
    let requestPermission: () -> Void
    let openSystemSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("通知", subtitle: "出し忘れを防ぐため、直近60日分を再設定します", systemImage: AppIcon.notification)

            notificationStatusView

            Toggle("前日20:00に通知", isOn: binding(\.previousNightNotificationEnabled))
                .minimumTapTarget()
            Toggle("当日7:30に通知", isOn: binding(\.morningNotificationEnabled))
                .minimumTapTarget()
            Toggle("年末年始注意を表示", isOn: binding(\.yearEndNoticeEnabled))
                .minimumTapTarget()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("ごみ種別ごとの通知")
                    .font(AppTypography.cardTitle)
                ForEach(categories) { category in
                    Toggle(isOn: Binding(
                        get: { settings.notificationEnabled(for: category.id) },
                        set: { setCategory($0, category.id) }
                    )) {
                        HStack(spacing: AppSpacing.sm) {
                            WasteSymbol(category: category, size: 32)
                            Text(category.name)
                        }
                    }
                    .minimumTapTarget()
                }
            }

            Button("通知を許可して再設定", action: requestPermission)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppColor.appTint)
                .frame(maxWidth: .infinity)

            NotificationPreviewList(previews: previews, categoryProvider: categoryProvider)
        }
        .appCard()
    }

    @ViewBuilder
    private var notificationStatusView: some View {
        switch status {
        case .authorized, .provisional, .ephemeral:
            InlineSettingsMessage(message: SettingsMessage(kind: .success, text: "通知は許可されています。設定変更後は再設定してください。"))
        case .denied:
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                InlineSettingsMessage(message: SettingsMessage(kind: .error, text: "通知が許可されていません。iOS設定から通知をオンにしてください。"))
                Button("iOS設定を開く", action: openSystemSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        case .notDetermined:
            InlineSettingsMessage(message: SettingsMessage(kind: .success, text: "まだ通知許可を確認していません。必要なときに許可できます。"))
        @unknown default:
            InlineSettingsMessage(message: SettingsMessage(kind: .error, text: "通知状態を確認できませんでした。iOS設定をご確認ください。"))
        }
    }

    private func binding(_ keyPath: WritableKeyPath<UserSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: {
                settings[keyPath: keyPath] = $0
                saveSettings()
            }
        )
    }
}

private struct NotificationPreviewList: View {
    let previews: [NotificationPreview]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("通知予定プレビュー")
                .font(AppTypography.cardTitle)
            if previews.isEmpty {
                InlineSettingsMessage(message: SettingsMessage(kind: .error, text: "通知予定がありません。通知がオフ、または直近60日に対象がない可能性があります。"))
            } else {
                ForEach(previews) { preview in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        WasteSymbol(category: categoryProvider(preview.categoryId), size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(preview.timing.label) \(KadomaDateFormatter.timestamp.string(from: preview.fireDate))")
                                .font(AppTypography.badge)
                                .foregroundStyle(AppColor.secondaryText)
                            Text(preview.title)
                                .font(AppTypography.callout.weight(.semibold))
                            Text(preview.body)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.secondaryText)
                                .lineLimit(3)
                            Text("対象日: \(KadomaDateFormatter.displayDay.string(from: preview.eventDate))")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.tertiaryText)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.top, AppSpacing.sm)
    }
}

private struct DataUpdateSettingsCard: View {
    @ObservedObject var store: MasterStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("データ更新", subtitle: "GitHub Pagesのmaster JSONを確認します", systemImage: AppIcon.update)
            LabeledContent("年度", value: "\(store.master.fiscalYear)年度")
            LabeledContent("バージョン", value: store.master.version)
            LabeledContent("公式更新日", value: store.master.sourceUpdatedAt)
            if let checkedAt = store.settings.lastMasterCheckAt {
                LabeledContent("最終確認", value: checkedAt)
            }

            Button {
                Task { await store.refreshMaster() }
            } label: {
                Label(store.isSyncing ? "確認中" : "マスタ更新を確認", systemImage: AppIcon.update)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.appTint)
            .disabled(store.isSyncing)

            if store.isSyncing {
                InlineLoadingMessage(text: "公式マスタのmanifestとSHA-256を確認しています。")
            } else if let syncMessage = store.syncMessage {
                InlineSettingsMessage(message: SettingsMessage(kind: syncMessage.contains("失敗") ? .error : .success, text: syncMessage))
            }
        }
        .appCard()
    }
}

private struct DisplayAccessibilityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("表示と使いやすさ", subtitle: "明るいライトモード専用です", systemImage: AppIcon.lightMode)
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.lightMode)
                    .font(.title2.weight(.heavy))
                    .frame(width: 48, height: 48)
                    .background(AppColor.softYellow, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .foregroundStyle(AppColor.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("ライトモード専用")
                        .font(AppTypography.cardTitle)
                    Text("色の見え方を安定させ、カレンダーとごみ種別を読み取りやすくするため、アプリ内は明るい表示に固定しています。文字サイズ変更とVoiceOverは引き続き確認対象です。")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}

private struct OfficialLinksCard: View {
    let pages: [SourcePage]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("公式情報", subtitle: "最終確認は門真市公式ページで行ってください", systemImage: AppIcon.official)
            ForEach(pages) { page in
                if let url = URL(string: page.url) {
                    Link(destination: url) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(page.title)
                                    .font(AppTypography.cardTitle)
                                Text("更新日: \(page.updatedAt)")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(AppColor.appTint)
                        }
                        .minimumTapTarget()
                    }
                }
            }
        }
        .appCard()
    }
}

private struct HelpAndAppInfoCard: View {
    let resetOnboarding: () -> Void
    let versionTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("アプリ情報", subtitle: "非公式アプリです", systemImage: AppIcon.info)
            Text("本アプリは門真市公式アプリではありません。情報は門真市公式情報をもとに作成しています。年末年始や災害時などは公式情報をご確認ください。")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button("初回案内をもう一度見る", action: resetOnboarding)
                .buttonStyle(.bordered)
                .controlSize(.large)
            Button(action: versionTapped) {
                LabeledContent("バージョン", value: "1.0")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("開発者用機能を表示する隠し操作です。通常利用では操作不要です。")
            LabeledContent("表示モード", value: "ライトモード専用")
            LabeledContent("文字サイズ", value: "Dynamic Type対応")
        }
        .appCard()
    }
}

private struct DeveloperSettingsEntryCard: View {
    @ObservedObject var store: MasterStore
    let isDebugBuild: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("開発者用", subtitle: isDebugBuild ? "DEBUGビルドでは常時表示します" : "隠し操作で有効化されています", systemImage: "hammer.fill")
            NavigationLink {
                DeveloperNotificationTestView(store: store)
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: AppIcon.notification)
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppColor.backgroundTop, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .foregroundStyle(AppColor.appTint)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("通知テストと検証情報")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColor.text)
                        Text("テスト通知、pending通知、マスタ情報を確認します。通常利用には不要です。")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColor.tertiaryText)
                }
                .minimumTapTarget()
            }
            .buttonStyle(.plain)
        }
        .appCard()
    }
}

private struct DeveloperNotificationTestView: View {
    @ObservedObject var store: MasterStore

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingRequests: [UNNotificationRequest] = []
    @State private var lastResult: SettingsMessage?
    @State private var isRunning = false
    @State private var confirmCancelAll = false

    private let notificationService = NotificationService()

    var body: some View {
        AppScreen {
            developerStatusCard
            notificationTestCard
            pendingNotificationsCard
            developerDataCard
        }
        .navigationTitle("開発者用")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await refreshState()
        }
        .confirmationDialog("すべてのpending通知を削除しますか？", isPresented: $confirmCancelAll, titleVisibility: .visible) {
            Button("すべて削除", role: .destructive) {
                notificationService.cancelAllPendingNotifications()
                Task { await refreshState(result: SettingsMessage(kind: .success, text: "すべてのpending通知を削除しました。通常通知も削除されます。")) }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("通常の収集通知も削除されます。実機検証時だけ使用してください。")
        }
    }

    private var developerStatusCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("通知許可状態", subtitle: "実機通知テストの前に確認します", systemImage: AppIcon.notification)
            LabeledContent("状態", value: authorizationStatus.displayLabel)
            if let lastResult {
                InlineSettingsMessage(message: lastResult)
            }
            Button {
                run("通知許可") {
                    let granted = try await notificationService.requestAuthorization()
                    return granted ? "通知が許可されました。" : "通知は許可されませんでした。iOS設定を確認してください。"
                }
            } label: {
                Label("通知許可をリクエスト", systemImage: AppIcon.notification)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.appTint)
            .disabled(isRunning)
        }
        .appCard()
    }

    private var notificationTestCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("テスト通知", subtitle: "通常通知とは別identifierで送ります", systemImage: "paperplane.fill")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    notificationButton("5秒後に送る", systemImage: "timer") {
                        try await notificationService.scheduleDeveloperTestNotification(after: 5)
                        return "5秒後のテスト通知を登録しました。"
                    }
                    notificationButton("10秒後に送る", systemImage: "timer") {
                        try await notificationService.scheduleDeveloperTestNotification(after: 10)
                        return "10秒後のテスト通知を登録しました。"
                    }
                }
                VStack(spacing: AppSpacing.sm) {
                    notificationButton("5秒後に送る", systemImage: "timer") {
                        try await notificationService.scheduleDeveloperTestNotification(after: 5)
                        return "5秒後のテスト通知を登録しました。"
                    }
                    notificationButton("10秒後に送る", systemImage: "timer") {
                        try await notificationService.scheduleDeveloperTestNotification(after: 10)
                        return "10秒後のテスト通知を登録しました。"
                    }
                }
            }
            notificationButton("明日のごみ通知を模擬", systemImage: "moon.stars.fill") {
                try await notificationService.scheduleDeveloperWasteSimulation(kind: .tomorrow, categoryName: representativeCategoryName(kind: .tomorrow))
                return "明日のごみ通知を模擬登録しました。"
            }
            notificationButton("今日の朝通知を模擬", systemImage: "sun.max.fill") {
                try await notificationService.scheduleDeveloperWasteSimulation(kind: .morning, categoryName: representativeCategoryName(kind: .morning))
                return "今日の朝通知を模擬登録しました。"
            }
            Text("テスト通知IDは \(NotificationService.developerTestIdentifierPrefix) で始まります。通常の収集通知はこの操作では削除しません。")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard()
    }

    private var pendingNotificationsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("pending通知", subtitle: "\(pendingRequests.count)件を確認中", systemImage: "list.bullet.rectangle")
            if pendingRequests.isEmpty {
                InlineSettingsMessage(message: SettingsMessage(kind: .success, text: "pending通知はありません。"))
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(pendingRequests.prefix(16), id: \.identifier) { request in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.content.title.isEmpty ? "タイトルなし" : request.content.title)
                                .font(AppTypography.callout.weight(.semibold))
                                .foregroundStyle(AppColor.text)
                            Text(request.identifier)
                                .font(AppTypography.footnote)
                                .foregroundStyle(request.identifier.hasPrefix(NotificationService.developerTestIdentifierPrefix) ? AppColor.appTint : AppColor.secondaryText)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.sm)
                        .background(AppColor.elevatedCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    Button("再読み込み") {
                        Task { await refreshState() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button("テスト通知だけ削除") {
                        Task {
                            await notificationService.cancelDeveloperTestNotifications()
                            await refreshState(result: SettingsMessage(kind: .success, text: "テスト通知だけを削除しました。"))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                VStack(spacing: AppSpacing.sm) {
                    Button("再読み込み") {
                        Task { await refreshState() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button("テスト通知だけ削除") {
                        Task {
                            await notificationService.cancelDeveloperTestNotifications()
                            await refreshState(result: SettingsMessage(kind: .success, text: "テスト通知だけを削除しました。"))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            Button(role: .destructive) {
                confirmCancelAll = true
            } label: {
                Label("すべてのpending通知を削除", systemImage: "trash.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .appCard()
    }

    private var developerDataCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("マスタ情報", subtitle: "開発者向けの確認用です", systemImage: AppIcon.update)
            LabeledContent("municipalityCode", value: store.master.municipalityCode)
            LabeledContent("master version", value: store.master.version)
            LabeledContent("areas", value: "\(store.master.areas.count)")
            LabeledContent("items", value: "\(store.master.itemDictionary.count)")
            LabeledContent("manifest URL", value: store.settings.remoteManifestURL)
            if let checkedAt = store.settings.lastMasterCheckAt {
                LabeledContent("last check", value: checkedAt)
            }
            if let refreshedAt = store.settings.lastSuccessfulMasterRefreshAt {
                LabeledContent("last success", value: refreshedAt)
            }
        }
        .appCard()
    }

    private func notificationButton(_ title: String, systemImage: String, action: @escaping () async throws -> String) -> some View {
        Button {
            run(title, action: action)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(isRunning)
    }

    @MainActor
    private func run(_ label: String, action: @escaping () async throws -> String) {
        isRunning = true
        lastResult = SettingsMessage(kind: .success, text: "\(label)を実行しています。")
        Task {
            do {
                let result = try await action()
                await refreshState(result: SettingsMessage(kind: .success, text: result))
            } catch {
                await refreshState(result: SettingsMessage(kind: .error, text: error.localizedDescription))
            }
            await MainActor.run {
                isRunning = false
            }
        }
    }

    @MainActor
    private func refreshState(result: SettingsMessage? = nil) async {
        authorizationStatus = await notificationService.authorizationStatus()
        let requests = await notificationService.pendingRequests()
        pendingRequests = requests.sorted { $0.identifier < $1.identifier }
        if let result {
            lastResult = result
        }
    }

    @MainActor
    private func representativeCategoryName(kind: DeveloperNotificationKind) -> String {
        let summary = store.collectionSummary()
        let events = kind == .tomorrow ? summary.tomorrow.events : summary.today.events
        let category = events.compactMap { store.category(for: $0.categoryId) }.first
            ?? store.category(for: "burnable")
            ?? store.master.categories.first
        return category?.name ?? "普通ごみ"
    }
}

private struct InlineSettingsMessage: View {
    let message: SettingsMessage

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: message.kind == .success ? AppIcon.success : AppIcon.error)
                .foregroundStyle(message.kind == .success ? AppColor.success : AppColor.error)
            Text(message.text)
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background((message.kind == .success ? AppColor.success : AppColor.error).opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct InlineLoadingMessage: View {
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text(text)
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
        }
        .padding(AppSpacing.md)
        .background(AppColor.appTint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private extension UNAuthorizationStatus {
    var displayLabel: String {
        switch self {
        case .notDetermined:
            return "未確認"
        case .denied:
            return "拒否"
        case .authorized:
            return "許可"
        case .provisional:
            return "仮許可"
        case .ephemeral:
            return "一時許可"
        @unknown default:
            return "不明"
        }
    }
}

#Preview("Settings Simple Default") {
    SettingsView()
        .environmentObject(MasterStore())
}

#Preview("Settings Simple Dynamic Type Large") {
    SettingsView()
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Settings Normal User") {
    SettingsView()
        .environmentObject(MasterStore())
}

#Preview("Settings Developer Mode") {
    SettingsView()
        .environmentObject(MasterStore())
}

#Preview("Developer Notification Test") {
    NavigationStack {
        DeveloperNotificationTestView(store: MasterStore())
    }
}

#Preview("Developer Pending Notifications") {
    NavigationStack {
        DeveloperNotificationTestView(store: MasterStore())
    }
    .previewLayout(.fixed(width: 393, height: 852))
}
