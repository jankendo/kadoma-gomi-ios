import Foundation

struct WasteSearchService {
    let items: [WasteItem]

    func search(_ query: String) -> [WasteItem] {
        let normalized = normalize(query)
        guard !normalized.isEmpty else {
            return Array(items.prefix(12))
        }

        return items
            .map { item in (item, score(item: item, query: normalized)) }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 == $1.1 {
                    return ($0.0.names.first ?? "") < ($1.0.names.first ?? "")
                }
                return $0.1 > $1.1
            }
            .map(\.0)
    }

    private func score(item: WasteItem, query: String) -> Int {
        var score = 0
        for name in item.names.map(normalize) {
            if name == query { score += 100 }
            if name.contains(query) { score += 60 }
            if query.contains(name) { score += 30 }
        }
        for keyword in item.keywords.map(normalize) where keyword.contains(query) || query.contains(keyword) {
            score += 20
        }
        if normalize(item.notes).contains(query) {
            score += 8
        }
        return score
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "ごみ", with: "ゴミ")
    }
}
