import SwiftUI

enum AppColor {
    static let appTint = Color(hex: "#0A8F8A")
    static let subTint = Color(hex: "#2F7EEB")
    static let accent = Color(hex: "#F59E0B")
    static let warning = Color(hex: "#D97706")
    static let success = Color(hex: "#219653")
    static let error = Color(hex: "#D94B4B")
    static let official = Color(hex: "#54748A")

    static let background = Color(hex: "#F7FBF3")
    static let backgroundTop = Color(hex: "#E9F8F2")
    static let backgroundBottom = Color(hex: "#FFF7E8")
    static let secondaryBackground = Color(hex: "#EEF7FF")
    static let cardBackground = Color.white
    static let elevatedCardBackground = Color(hex: "#FFFDF7")
    static let separator = Color(hex: "#D7E3DD")
    static let text = Color(hex: "#24312F")
    static let secondaryText = Color(hex: "#566B66")
    static let tertiaryText = Color(hex: "#7D918B")
    static let softYellow = Color(hex: "#FFF2BF")
    static let softMint = Color(hex: "#DCFCE7")
    static let softBlue = Color(hex: "#DBEAFE")
    static let softCoral = Color(hex: "#FFE2DD")

    static func category(_ category: WasteCategory?) -> Color {
        guard let id = category?.id else { return appTint }
        switch id {
        case "burnable":
            return Color(hex: "#F97357")
        case "plastic_container":
            return Color(hex: "#22A06B")
        case "bottles_cans":
            return Color(hex: "#2F8EDB")
        case "paper_cloth":
            return Color(hex: "#B7792E")
        case "small_items":
            return Color(hex: "#7367F0")
        case "pet_bottle":
            return Color(hex: "#14A6C8")
        case "bulky":
            return Color(hex: "#C46A2F")
        case "recycle_law":
            return Color(hex: "#667085")
        case "hazardous_note":
            return error
        default:
            return Color(hex: category?.colorHex ?? "#0A8F8A")
        }
    }

    static func categoryBackground(_ category: WasteCategory?) -> Color {
        Self.category(category).opacity(0.15)
    }

    static func softBackground(for color: Color) -> Color {
        color.opacity(0.13)
    }
}
