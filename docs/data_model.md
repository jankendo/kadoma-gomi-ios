# Data Model

## 1. データファイル一覧

Runtime互換:

- `KadomaGomi/Resources/initial_master_27223_2026.json`
- `docs/kadoma_27223_2026_master.json`
- `docs/manifest.json`

分割管理用:

- `KadomaGomi/Resources/Data/garbage_categories.json`
- `KadomaGomi/Resources/Data/garbage_items.json`
- `KadomaGomi/Resources/Data/collection_areas.json`
- `KadomaGomi/Resources/Data/collection_schedule.json`
- `KadomaGomi/Resources/Data/special_rules.json`

公式監視:

- `docs/source_hashes.json`
- `Scripts/check_kadoma_sources.py`

## 2. 各データの役割

- `initial_master_27223_2026.json`: アプリが起動時に読み込む初期マスタ。既存互換を維持するためruntimeの主データ。
- `kadoma_27223_2026_master.json`: GitHub Pages配信用master。
- `manifest.json`: 最新version、master URL、SHA-256、更新日、メッセージ。
- `garbage_categories.json`: ごみ種別、色、アイコン、出し方、通知初期値。
- `garbage_items.json`: 品目辞書100件、表記ゆれ、キーワード、注意、信頼度。
- `collection_areas.json`: 地区、町名、将来の番地範囲ルール。
- `collection_schedule.json`: 地区別収集ルール。
- `special_rules.json`: 例外日と注意通知。
- `source_hashes.json`: 公式HTML/PDFのSHA-256ベースライン。

## 3. スキーマ

### MunicipalityMaster

- `municipalityCode`
- `municipalityName`
- `targetAddressPreset`
- `defaultAreaId`
- `fiscalYear`
- `version`
- `sourceUpdatedAt`
- `generatedAt`
- `sourcePages`
- `areas`
- `categories`
- `itemDictionary`
- `notices`

### CollectionArea

- `id`
- `name`
- `towns`
- `schedules`
- `exceptions`

### ScheduleRule

- `id`
- `categoryId`
- `recurrenceType`: `weekly` / `monthlyNthWeekday` / `specificDates`
- `weekdays`: 1=月, 2=火, 3=水, 4=木, 5=金, 6=土, 7=日
- `weekOfMonth`
- `specificDates`
- `validFrom`
- `validTo`

### WasteItem

- `id`
- `names`
- `categoryId`
- `keywords`
- `notes`
- `source`
- `confidence`

## 4. 更新方法

1. 公式ページ監視workflowでHTML/PDFのSHA-256差分を確認。
2. 差分があれば`source-report` artifactをレビュー。
3. 必要に応じて分割JSONを更新。
4. `initial_master_27223_2026.json`と`docs/kadoma_27223_2026_master.json`へ反映。
5. `docs/manifest.json`の`latestVersion`と`sha256`を更新。
6. GitHub Pagesへdeploy。
7. アプリの「マスタ更新を確認」でremote masterを取得。

## 5. 公式情報との関係

- 地区と曜日ルールは門真市公式「地区別ごみカレンダー」を基準にする。
- 分別説明は門真市公式「ごみの出し方・分け方」を基準にする。
- 粗大ごみは電話申込み/Web申込み公式ページを基準にする。
- PDF画像や公式アイコンは再配布せず、事実データをJSON化して表示する。

## 6. 門真市大倉町1-20への対応状況

- `targetAddressPreset`: `大倉町1-20`
- `defaultAreaId`: `A`
- `collection_areas.json`: 大倉町 -> A地区
- `AddressResolver`: 大倉町を含む住所をA地区として判定
- Onboarding / 設定画面: 大倉町1-20プリセットを提供

## 7. 今後の自動更新案

- 分割JSONをsource-of-truthにし、master JSONを生成するスクリプトを追加する。
- A-F全地区の町名/番地範囲を`collection_areas.json`へ拡張する。
- PDF例外日だけは自動抽出後に人間レビューする。
- manifestに`requiresReview`を立て、アプリ側で「公式データ未確認」警告を出す。

## 8. 注意点

- 現時点のruntimeはmonolithic masterを読み込む。分割JSONは将来更新・レビューを楽にするための追加データ。
- 年末年始の実日付変更は通常ルールだけでは確定できない。
- 品目辞書の`confidence`が低いものは公式確認推奨としてUIで表示する。

## 9. Phase 2追記

第2フェーズから、分割JSONを編集元、`initial_master_27223_2026.json` と `docs/kadoma_27223_2026_master.json` を生成物として扱う。A-F全地区の町名・収集ルールは `collection_areas.json` と `collection_schedule.json` に入り、`Scripts/generate_master.py` で本番masterへ変換する。

`sourceStatus` は分割JSON側で管理し、公式確認済み・レビュー対象・未確認を区別する。アプリのCodable互換を守るため、生成masterでは既存モデルが読むフィールドへ整形する。

データ検証は `Scripts/validate_data.py` と `Scripts/run_quality_checks.py` で行う。manifest SHAは配信用masterの実バイト列から生成し、WindowsとCIで改行差分が出ないようLF固定で書き出す。

## 10. Phase 3追記

検索辞書を225件へ拡張し、品目ごとに `displayName`、`kana`、`aliases`、`disposalGuide`、`warnings`、`isOversizedCandidate`、`isHazardous`、`requiresOfficialCheck`、`sourceUrl`、`confidenceStatus`、`updatedAt` を追加した。

`special_rules.json` は未確認の実例外日を確定登録しない設計に変更した。`exceptions` は confirmed のみ、`exceptionRules` は年末年始などレビュー対象期間を表す。2026年12月から2027年1月は `needs_review` として扱う。

将来の Widget / App Shortcuts 用に `GarbageSummaryProvider`、`DayCollectionSummary`、`AreaCollectionSummary` を追加した。ホーム・通知・Widget・Siri 系機能が同じ読み取り専用サマリーを使えるようにするための入口である。

## 11. Phase 4追記

第4フェーズではデータ構造を変更していない。`master version 2026.04.01-af.3`、A-F地区、225品目、Dec/Jan `needs_review` ルール、manifest/SHA生成を維持し、UI層のみをライトモード専用デザインへ更新した。
## Phase 5: 分別方法ガイド拡張

2026-05-25に、門真市公式「ごみの出し方・分け方」と共通PDFを根拠に、カテゴリ/品目の説明力を強化した。

### カテゴリ追加フィールド

- `description`
- `disposalSummary`
- `disposalSteps`
- `warnings`
- `examples`
- `collectionMethod`
- `requiresReservation`
- `requiresOfficialCheck`
- `sourceUrl`
- `sourceTitle`
- `confidenceStatus`
- `updatedAt`

### 品目追加フィールド

- `subcategoryName`
- `disposalSteps`
- `preparationBeforeDisposal`
- `sizeRule`
- `bundleRule`
- `washingRequired`
- `removeCapsLabels`
- `drainContents`
- `separateMaterials`
- `requiresReservation`
- `sourceTitle`

Swift側はoptionalとして読み込むため、古いremote masterとの互換性を維持する。
