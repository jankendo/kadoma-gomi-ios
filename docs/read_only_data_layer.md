# Read Only Data Layer

## 1. 目的

ホーム画面、Widget、App Shortcuts、Siri/App Intents、通知、将来のロック画面表示が、同じ収集データを安全に参照できるようにするための読み取り専用層です。

## 2. 設計方針

UIが直接 `CalendarGenerateService` を呼び分けるのではなく、`GarbageSummaryProvider` が地区設定、master、収集予定、注意情報をまとめて返します。書き込みや通知登録は行わず、純粋に読み取り専用です。

## 3. 提供するデータ

- 設定中地区
- 設定住所
- 今日の収集予定
- 明日の収集予定
- 次回収集予定
- master version
- sourceUpdatedAt
- 年末年始などの notice
- needs_review の exceptionRules
- 公式確認が必要かどうか

## 4. 既存UIとの関係

Phase 3 では `HomeView` と `MasterStore` が段階的に `GarbageSummaryProvider` を使うようにしました。既存画面の挙動を壊さないため、検索、設定、カレンダーは既存の `MasterStore` API を維持しています。

## 5. Widget対応時の使い方

Widget 側では App Group 共有ストレージから master と settings を読み、`GarbageSummaryProvider.areaSummary(referenceDate:)` を呼びます。書き込みや通知許可に依存しないため、Widget Timeline 生成に向いています。

## 6. App Shortcuts対応時の使い方

App Intent から `GarbageSummaryProvider` を呼ぶことで、「今日のごみ」「明日のごみ」「次回のごみ」を同じロジックで返せます。Phase 3 では App Intents 自体は追加していません。

## 7. 今回実装した範囲

- `GarbageSummaryProvider`
- `DayCollectionSummary`
- `AreaCollectionSummary`
- `MasterStore.collectionSummary(referenceDate:nextLimit:)`
- `HomeView` の今日/明日/次回表示への段階適用

## 8. 今後の実装TODO

- App Group 対応の共有読み取りストアを追加する。
- WidgetKit TimelineProvider を追加する。
- App Shortcuts / App Intents を追加する。
- 通知スケジューラも provider の summary を入力にする。
