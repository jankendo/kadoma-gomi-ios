import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: MasterStore
    @Environment(\.openURL) private var openURL

    @State private var addressText = ""
    @State private var addressMessage: SettingsMessage?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

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
                OfficialLinksCard(pages: store.master.sourcePages)
                HelpAndAppInfoCard(
                    resetOnboarding: {
                        store.resetOnboarding()
                    }
                )
            }
            .navigationTitle("設定")
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
            AppSectionHeader("地区設定", subtitle: "地区を間違えると収集日が変わります", systemImage: AppIcon.district)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("現在")
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.secondaryText)
                Text("門真市 \(currentAddress) / \(currentAreaName)")
                    .font(AppTypography.cardTitle)
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
            Button("保存", action: save)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppColor.appTint)
            Button("大倉町1-20を使う", action: applyPreset)
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
            TextField("manifest URL", text: Binding(
                get: { store.settings.remoteManifestURL },
                set: {
                    store.settings.remoteManifestURL = $0
                    store.saveSettings()
                }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)

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
            LabeledContent("バージョン", value: "1.0")
            LabeledContent("ダークモード", value: "対応")
            LabeledContent("文字サイズ", value: "Dynamic Type対応")
        }
        .appCard()
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

#Preview {
    SettingsView()
        .environmentObject(MasterStore())
}

#Preview("Settings Dark Large Type") {
    SettingsView()
        .environmentObject(MasterStore())
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}
