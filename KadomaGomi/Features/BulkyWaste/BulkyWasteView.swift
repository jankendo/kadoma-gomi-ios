import SwiftUI

struct BulkyWasteView: View {
    var body: some View {
        NavigationStack {
            AppScreen {
                BulkyHeroCard()
                BulkyActionSection()
                BulkyStepsSection()
                BulkyCautionSection()
            }
            .navigationTitle("粗大ごみ")
            .toolbarBackground(AppColor.backgroundTop, for: .navigationBar)
        }
    }
}

private struct BulkyHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                WasteSymbol(category: WasteCategory(
                    id: "bulky",
                    name: "粗大ごみ",
                    shortName: "粗大",
                    symbolName: AppIcon.bulky,
                    colorHex: "#E8791A",
                    disposalRule: "電話予約と処理券が必要です。",
                    notes: [],
                    defaultPreviousNightNotification: false,
                    defaultMorningNotification: false
                ), size: 56)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("30cmを超えるものは要予約")
                        .font(.title2.weight(.bold))
                    Text("木曜扱いでも、予約なしでは出せません。申し込み、処理券、収集日を先に確認してください。")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}

private struct BulkyActionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("申し込み", subtitle: "初回や住所変更後は電話申込が必要です", systemImage: "phone.fill")

            Link(destination: URL(string: "tel:0662927030")!) {
                Label("06-6292-7030 に電話", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.appTint)

            Link(destination: URL(string: "tel:0728847030")!) {
                Label("072-884-7030 に電話", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Link(destination: URL(string: "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22408.html")!) {
                Label("Web申込の条件を確認", systemImage: "safari.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .appCard()
    }
}

private struct BulkyStepsSection: View {
    private let steps = [
        ("1", "電話またはWeb条件を確認", "初回、住所・氏名・電話番号変更後などは電話で確認します。"),
        ("2", "収集日と料金を確認", "収集日の3か月前から2日前までが目安です。土日は除きます。"),
        ("3", "処理券を用意", "300円券または600円券が必要です。"),
        ("4", "指定日に出す", "粗大ごみはごみ袋に入れる必要はありません。")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("出すまでの流れ", subtitle: "予約から収集日までを確認", systemImage: "checklist")
            ForEach(steps, id: \.0) { number, title, bodyText in
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    Text(number)
                        .font(AppTypography.badge)
                        .frame(width: 28, height: 28)
                        .background(AppColor.appTint, in: Circle())
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(title)
                            .font(AppTypography.cardTitle)
                        Text(bodyText)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .appCard()
    }
}

private struct BulkyCautionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("注意", subtitle: "迷ったら公式ページを確認してください", systemImage: AppIcon.warning)
            AppBadge("要予約", color: AppColor.warning, systemImage: AppIcon.warning)
            Text("このアプリは曜日の目安と申し込み導線を表示します。粗大ごみは必ず門真市の受付条件を確認してから出してください。")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Link("門真市公式の粗大ごみ電話申込みページ", destination: URL(string: "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22406.html")!)
                .font(AppTypography.callout.weight(.semibold))
        }
        .appCard()
    }
}

#Preview {
    BulkyWasteView()
}
