import SwiftUI

enum AppColor {
    static let appTint = Color(hex: "#3F9D57")
    static let header = Color(hex: "#49A65A")
    static let subTint = Color(hex: "#52796F")
    static let accent = Color(hex: "#F28C28")
    static let warning = Color(hex: "#B7791F")
    static let success = Color(hex: "#219653")
    static let error = Color(hex: "#C94A4A")
    static let official = Color(hex: "#5E6E75")

    static let background = Color(hex: "#F7F8F6")
    static let backgroundTop = Color(hex: "#E8F2E7")
    static let backgroundBottom = Color(hex: "#F7F8F6")
    static let secondaryBackground = Color(hex: "#EEF5ED")
    static let cardBackground = Color.white
    static let elevatedCardBackground = Color(hex: "#FAFBF9")
    static let separator = Color(hex: "#D7DDD6")
    static let text = Color(hex: "#333A36")
    static let secondaryText = Color(hex: "#5F6762")
    static let tertiaryText = Color(hex: "#8A928D")
    static let softYellow = Color(hex: "#FFF5DA")
    static let softMint = Color(hex: "#E6F3E4")
    static let softBlue = Color(hex: "#E8F0F8")
    static let softCoral = Color(hex: "#FCE7E4")

    static func category(_ category: WasteCategory?) -> Color {
        guard let id = category?.id else { return appTint }
        switch id {
        case "burnable":
            return Color(hex: "#D97745")
        case "plastic_container":
            return Color(hex: "#3F9D57")
        case "bottles_cans":
            return Color(hex: "#3D7FA6")
        case "paper_cloth":
            return Color(hex: "#9A6B3A")
        case "small_items":
            return Color(hex: "#6B7280")
        case "pet_bottle":
            return Color(hex: "#2C8FA3")
        case "bulky":
            return Color(hex: "#8B6A4F")
        case "recycle_law":
            return Color(hex: "#667085")
        case "hazardous_note":
            return error
        default:
            return Color(hex: category?.colorHex ?? "#0A8F8A")
        }
    }

    static func categoryBackground(_ category: WasteCategory?) -> Color {
        Self.category(category).opacity(0.10)
    }

    static func softBackground(for color: Color) -> Color {
        color.opacity(0.13)
    }
}
