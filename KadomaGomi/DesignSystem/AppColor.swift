import SwiftUI

enum AppColor {
    static let appTint = Color(red: 0.0, green: 0.36, blue: 0.42)
    static let subTint = Color(red: 0.08, green: 0.48, blue: 0.40)
    static let warning = Color(red: 0.86, green: 0.45, blue: 0.10)
    static let success = Color(red: 0.12, green: 0.55, blue: 0.33)
    static let error = Color(red: 0.78, green: 0.16, blue: 0.20)

    static let background = Color(.systemGroupedBackground)
    static let secondaryBackground = Color(.secondarySystemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
    static let elevatedCardBackground = Color(.secondarySystemBackground)
    static let separator = Color(.separator)
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)

    static func category(_ category: WasteCategory?) -> Color {
        Color(hex: category?.colorHex ?? "#005C68")
    }
}

