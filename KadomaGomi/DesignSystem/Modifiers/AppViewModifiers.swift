import SwiftUI

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: AppShadow.cardColor, radius: AppShadow.subtleRadius, x: 0, y: AppShadow.subtleY)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func minimumTapTarget() -> some View {
        frame(minHeight: 44)
    }
}

