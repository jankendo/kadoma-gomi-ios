# Data Quality

## 1. 第2フェーズの改善

- A-F全地区を `collection_areas.json` に追加。
- A-F全地区の収集曜日を `collection_schedule.json` に追加。
- 各地区・収集ルールに `sourceStatus` を付与。
- 分割JSONから本番master/manifestを生成できるようにした。
- schema validation、参照整合性、SHA検証、カレンダースモークテストをCI対象にした。

## 2. 確認済みデータ

門真市公式ページで確認した内容:

- 門真市の収集地区はA地区からF地区。
- 大倉町はA地区。
- A-F各地区の普通ごみ、プラスチック製容器包装、びん・缶類、古紙古布、小型ごみ、ペットボトル、粗大ごみの曜日・第n水曜ルール。
- 収集日の朝9時までに出す案内。

## 3. 未確認またはレビュー対象

- 年末年始の実変更日。
- PDFカレンダー上の個別例外。
- 災害・台風などの臨時変更。
- `manual-initial` の品目辞書の一部。

## 4. 自動検出する不整合

- JSON parse error。
- schema違反。
- 地区ID/品目ID/カテゴリID/収集ルールIDの重複。
- 存在しないカテゴリ参照。
- 存在しない地区参照。
- 空カテゴリ。
- 日付フォーマット不正。
- A-F地区不足。
- 大倉町 -> A地区ルール不足。
- manifest SHA不一致。

## 5. 低信頼度データ

`confidence < 0.6` の品目は検証スクリプトで警告する。アプリUIでは `公式確認推奨` バッジを表示する。

## 6. 運用ルール

通常は分割JSONを編集し、`generate_master.py --write` で生成物を更新する。`initial_master_27223_2026.json` や `docs/kadoma_27223_2026_master.json` を直接編集しない。

## 7. Phase 3追加チェック

- 検索辞書が200件以上であること。
- 品目に `confidenceStatus` があること。
- `confirmed` 以外の品目は `requiresOfficialCheck=true` であること。
- `sourceUrl` は門真市公式URLを優先すること。
- `special_rules.exceptions` は `confidence=confirmed` のみ登録できること。
- `special_rules.exceptionRules` は `sourceUrl`、`confirmedAt`、`confidence` を持つこと。
- 未確定年末年始ルールは warning として検出すること。
- master に `exceptionRules` が含まれること。
- manifest SHA が docs master と一致すること。

Phase 3 時点の意図的な warning は、公式確認推奨品目と alias 重複である。alias 重複は検索の実用性を上げるために許容し、ログでは先頭25件と残件数だけを表示する。
