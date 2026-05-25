import Foundation

struct WasteSearchService {
    let items: [WasteItem]
    let categories: [WasteCategory]

    init(items: [WasteItem], categories: [WasteCategory] = []) {
        self.items = items
        self.categories = categories
    }

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
        var totalScore = 0
        let variants = queryVariants(for: query)
        totalScore += scoreText(text: item.primaryName, variants: variants, exact: 120, contains: 70, reverseContains: 35)
        for name in item.names {
            totalScore += scoreText(text: name, variants: variants, exact: 100, contains: 60, reverseContains: 30)
        }
        for keyword in item.searchAliases {
            totalScore += scoreText(text: keyword, variants: variants, exact: 48, contains: 26, reverseContains: 12)
        }
        if let guide = item.disposalGuide {
            totalScore += scoreText(text: guide, variants: variants, exact: 0, contains: 10, reverseContains: 0)
        }
        for warning in item.warnings ?? [] {
            totalScore += scoreText(text: warning, variants: variants, exact: 0, contains: 8, reverseContains: 0)
        }
        if let category = categories.first(where: { $0.id == item.categoryId }) {
            totalScore += scoreText(text: category.name, variants: variants, exact: 70, contains: 45, reverseContains: 18)
            totalScore += scoreText(text: category.shortName, variants: variants, exact: 80, contains: 40, reverseContains: 18)
            totalScore += scoreText(text: category.disposalRule, variants: variants, exact: 0, contains: 6, reverseContains: 0)
            totalScore += scoreText(text: category.guideSummary, variants: variants, exact: 0, contains: 8, reverseContains: 0)
            for example in category.guideExamples {
                totalScore += scoreText(text: example, variants: variants, exact: 20, contains: 10, reverseContains: 6)
            }
        }
        if query == normalize("プラ") || query == normalize("プラスチック") {
            if item.categoryId == "plastic_container" {
                totalScore += 140
            }
            if item.categoryId == "burnable" {
                totalScore -= 35
            }
        }
        if query.contains(normalize("リチウム")) || query.contains(normalize("リチュウム")) || query.contains("liion") {
            if item.categoryId == "hazardous_note" {
                totalScore += 180
            }
            if item.primaryName == "電池" {
                totalScore -= 60
            }
        }
        if variants.contains(where: { normalize(item.notes).contains($0) }) {
            totalScore += 8
        }
        return totalScore
    }

    private func scoreText(text: String, variants: Set<String>, exact: Int, contains: Int, reverseContains: Int) -> Int {
        let normalized = normalize(text)
        return variants.reduce(0) { partialResult, variant in
            if normalized == variant {
                return partialResult + exact
            }
            if normalized.contains(variant) {
                return partialResult + contains
            }
            if variant.contains(normalized) {
                return partialResult + reverseContains
            }
            return partialResult
        }
    }

    private func queryVariants(for query: String) -> Set<String> {
        let normalized = normalize(query)
        guard !normalized.isEmpty else { return [] }

        let aliases: [String: [String]] = [
            "pet": ["ペット", "ペットボトル"],
            "ペット": ["PET", "ペットボトル"],
            "ボトル": ["ペットボトル", "プラスチックボトル"],
            "プラ": ["プラスチック", "プラスチック製容器包装"],
            "プラスチック": ["プラ", "プラスチック製容器包装"],
            "ダンボール": ["段ボール"],
            "段ボール": ["ダンボール"],
            "カン": ["缶"],
            "缶": ["カン"],
            "ビン": ["びん", "瓶"],
            "びん": ["ビン", "瓶"],
            "リチウム": ["リチウムイオン電池", "リチュウム", "リチューム"],
            "リチュウム": ["リチウム", "リチウムイオン電池"],
            "モバイル": ["モバイルバッテリー", "バッテリー"],
            "バッテリー": ["モバイルバッテリー", "充電式電池", "リチウムイオン電池"],
            "スプレー": ["スプレー缶", "ヘアスプレー缶", "塗料スプレー缶"],
            "ボンベ": ["カセットボンベ", "簡易ガスボンベ", "卓上コンロ用ボンベ"],
            "古着": ["衣類", "Tシャツ", "セーター", "ジーンズ"],
            "本": ["雑誌", "教科書", "書籍"],
            "粗大": ["粗大ごみ", "大型", "30cm超"],
            "大型": ["粗大ごみ", "30cm超"]
        ]

        var variants: Set<String> = [normalized]
        for (key, values) in aliases where normalize(key) == normalized {
            variants.formUnion(values.map(normalize))
        }
        return variants
    }

    private func normalize(_ text: String) -> String {
        let widthFolded = text.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
        let kanaFolded = widthFolded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? widthFolded
        return kanaFolded.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "ごみ", with: "ゴミ")
            .replacingOccurrences(of: "ー", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "・", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
}
