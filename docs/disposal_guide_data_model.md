# 分別方法データモデル

## 1. 目的

検索結果で「何ごみか」だけを出すのではなく、「どう出すか」「出す前に何をするか」「公式確認が必要か」まで一画面で理解できるようにする。

## 2. カテゴリ拡張フィールド

`garbage_categories.json` に以下を追加した。

- `displayName`
- `description`
- `iconName`
- `colorToken`
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

`disposalSteps` は3件以上をschema/validationでチェックする。

## 3. 品目拡張フィールド

`garbage_items.json` に以下を追加した。

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

既存の `displayName`, `aliases`, `warnings`, `isHazardous`, `isOversizedCandidate`, `requiresOfficialCheck`, `confidenceStatus` は維持した。

## 4. 互換性

Swiftの `WasteCategory` と `WasteItem` では新フィールドをoptionalとして定義した。古いremote masterを取得しても、既存フィールドだけで画面表示できる。

## 5. UI利用箇所

- ホーム: 今日/明日/次回の収集カテゴリから `disposalSummary`, `examples`, `disposalSteps`, `warnings` を表示
- 検索結果: `disposalSteps` の上位3件を表示
- 品目詳細: `disposalSteps`, チェック項目、警告、公式リンクを表示
- カテゴリ詳細: `description`, `examples`, `warnings`, 代表品目を表示

## 6. 検証

- schema validationでカテゴリ/品目の新フィールドを検証
- `run_quality_checks.py` で全カテゴリの手順と代表例、全品目の手順とsourceTitleを検証
- master/manifest/SHA生成は既存フローを維持
