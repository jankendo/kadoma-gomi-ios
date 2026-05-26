import SwiftUI

enum AppTypography {
    static let screenTitle = Font.title.weight(.bold)
    static let heroTitle = Font.title2.weight(.bold)
    static let heroNumber = Font.system(.title, design: .default).weight(.bold)
    static let sectionTitle = Font.title3.weight(.bold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let compactTitle = Font.subheadline.weight(.bold)
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let badge = Font.caption.weight(.bold)
    static let tinyBadge = Font.caption2.weight(.heavy)
}
