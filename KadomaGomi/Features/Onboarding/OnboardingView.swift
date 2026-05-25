import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void
    let skip: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "今日のごみがすぐ分かる",
            message: "開いたら最初に、今日と明日の収集予定を大きく表示します。",
            symbol: "calendar.badge.clock",
            color: AppColor.appTint
        ),
        .init(
            title: "ごみ名で分別を検索",
            message: "フライパン、ペット、スプレー缶など、迷いやすい品目をすぐ調べられます。",
            symbol: "magnifyingglass.circle.fill",
            color: AppColor.subTint
        ),
        .init(
            title: "門真市A-F地区に対応",
            message: "大倉町1-20はA地区プリセット。あとから設定画面でA-F地区を選べます。",
            symbol: "mappin.and.ellipse.circle.fill",
            color: AppColor.warning
        ),
        .init(
            title: "通知で出し忘れを防ぐ",
            message: "前日夜と当日朝の通知を使えます。許可は設定画面からいつでも変更できます。",
            symbol: "bell.badge.circle.fill",
            color: AppColor.success
        )
    ]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                Text("かどまごみナビ")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.appTint)
                Spacer()
                Button("スキップ", action: skip)
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(AppColor.secondaryText)
                    .minimumTapTarget()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item)
                        .tag(index)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == pages.count - 1 ? "A地区で始める" : "次へ") {
                if page == pages.count - 1 {
                    complete()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        page += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.appTint)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
            .accessibilityHint(page == pages.count - 1 ? "大倉町1-20をA地区として設定してホームを開きます。" : "次の説明へ進みます。")
        }
        .background(
            LinearGradient(
                colors: [AppColor.backgroundTop, AppColor.background, AppColor.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct OnboardingPage {
    let title: String
    let message: String
    let symbol: String
    let color: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer(minLength: 0)
            Image(systemName: page.symbol)
                .font(.system(size: 82, weight: .semibold))
                .foregroundStyle(page.color)
                .frame(width: 132, height: 132)
                .background(page.color.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .stroke(page.color.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: page.color.opacity(0.12), radius: 18, x: 0, y: 8)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.md) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.text)
                Text(page.message)
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(complete: {}, skip: {})
}

#Preview("Onboarding Light iPhone SE") {
    OnboardingView(complete: {}, skip: {})
        .previewLayout(.fixed(width: 320, height: 568))
}
