import SwiftUI

struct BulkyWasteView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("粗大ごみ")
                            .font(.largeTitle.bold())
                        Text("最大の辺または径が30cmを超える耐久消費財などは、電話予約と処理券が必要です。")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("毎週木曜扱いですが、出す前に予約が必要", systemImage: "calendar.badge.exclamationmark")
                        Label("申し込みは収集日の3か月前から2日前までが目安", systemImage: "clock.badge.exclamationmark")
                        Label("処理券は300円券または600円券", systemImage: "ticket.fill")
                    }
                    .font(.headline)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))

                    VStack(spacing: 10) {
                        Link(destination: URL(string: "tel:0662927030")!) {
                            Label("06-6292-7030 に電話", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Link(destination: URL(string: "tel:0728847030")!) {
                            Label("072-884-7030 に電話", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Link(destination: URL(string: "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22408.html")!) {
                            Label("Web申込の条件を確認", systemImage: "safari.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("受付時間")
                            .font(.headline)
                        Text("月曜から金曜の午前9時から午後6時まで。土日、祝日、年末年始は除きます。")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))

                    Link("門真市公式の粗大ごみ電話申込みページを開く", destination: URL(string: "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22406.html")!)
                        .font(.footnote)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("粗大ごみ")
        }
    }
}

