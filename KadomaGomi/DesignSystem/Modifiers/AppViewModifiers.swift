import SwiftUI

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColor.separator, lineWidth: 0.8)
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

    func appPillButtonBackground(_ color: Color = AppColor.appTint) -> some View {
        padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(color, in: Capsule())
            .foregroundStyle(.white)
    }
}
