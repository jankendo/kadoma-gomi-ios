import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var query = ""

    private var results: [WasteItem] {
        store.searchItems(query: query)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("例：フライパン、スプレー缶、布団", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(query.isEmpty ? "よく使う品目" : "検索結果") {
                    if results.isEmpty {
                        ContentUnavailableView("見つかりません", systemImage: "questionmark.circle", description: Text("公式ページ確認リンクから最新情報を確認してください。"))
                    } else {
                        ForEach(results) { item in
                            SearchResultRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("分別検索")
        }
    }
}

private struct SearchResultRow: View {
    @EnvironmentObject private var store: MasterStore
    let item: WasteItem

    var body: some View {
        let category = store.category(for: item.categoryId)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.names.first ?? item.id)
                    .font(.headline)
                Spacer()
                if let category {
                    Text(category.shortName)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: category.colorHex).opacity(0.14), in: Capsule())
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }
            Text(item.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !item.names.dropFirst().isEmpty {
                Text(item.names.dropFirst().joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

