import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var addressText = ""
    @State private var addressMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("地区設定") {
                    TextField("住所", text: $addressText)
                    Button("大倉町1-20 / A地区として保存") {
                        let ok = store.resolveAndSaveAddress(addressText)
                        addressMessage = ok ? "A地区として保存しました" : "地区を判定できませんでした"
                    }
                    Text("現在: 門真市 \(store.settings.addressText) / \(store.settings.areaId)地区")
                        .foregroundStyle(.secondary)
                    if let addressMessage {
                        Text(addressMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("通知") {
                    Toggle("前日20:00", isOn: binding(
                        get: { store.settings.previousNightNotificationEnabled },
                        set: { store.settings.previousNightNotificationEnabled = $0 }
                    ))
                    Toggle("当日7:30", isOn: binding(
                        get: { store.settings.morningNotificationEnabled },
                        set: { store.settings.morningNotificationEnabled = $0 }
                    ))
                    Toggle("年末年始注意", isOn: binding(
                        get: { store.settings.yearEndNoticeEnabled },
                        set: { store.settings.yearEndNoticeEnabled = $0 }
                    ))
                    Button {
                        Task { await store.rescheduleNotifications() }
                    } label: {
                        Label("通知を許可して再設定", systemImage: "bell.badge.fill")
                    }
                }

                Section("マスタ") {
                    LabeledContent("現在", value: "\(store.master.fiscalYear)年度版")
                    LabeledContent("バージョン", value: store.master.version)
                    LabeledContent("公式更新日", value: store.master.sourceUpdatedAt)
                    TextField("manifest URL", text: binding(
                        get: { store.settings.remoteManifestURL },
                        set: { store.settings.remoteManifestURL = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Button {
                        Task { await store.refreshMaster() }
                    } label: {
                        Label(store.isSyncing ? "確認中" : "公式マスタ更新を確認", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(store.isSyncing)
                    if let syncMessage = store.syncMessage {
                        Text(syncMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("公式情報") {
                    ForEach(store.master.sourcePages) { page in
                        Link(page.title, destination: URL(string: page.url)!)
                    }
                }

                Section {
                    Text("本アプリは門真市公式アプリではありません。情報は門真市公式情報をもとに作成しています。最終確認は公式情報をご確認ください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .onAppear {
                addressText = store.settings.addressText
            }
        }
    }

    private func binding<Value>(get: @escaping () -> Value, set: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: get,
            set: { value in
                set(value)
                store.saveSettings()
            }
        )
    }
}

