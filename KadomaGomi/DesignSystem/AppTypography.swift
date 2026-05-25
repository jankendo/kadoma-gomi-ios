import SwiftUI

enum AppTypography {
    static let screenTitle = Font.largeTitle.weight(.heavy)
    static let heroTitle = Font.title.weight(.heavy)
    static let heroNumber = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    static let sectionTitle = Font.title3.weight(.bold)
    static let cardTitle = Font.headline.weight(.bold)
    static let compactTitle = Font.subheadline.weight(.bold)
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let badge = Font.caption.weight(.bold)
    static let tinyBadge = Font.caption2.weight(.heavy)
}
