# Official Source Review Phase 3

## 1. 確認した公式ページ

- 門真市 地区別ごみカレンダー: https://www.city.kadoma.osaka.jp/kurashi/gomi/9/35805.html
- 門真市 ごみの出し方・分け方: https://www.city.kadoma.osaka.jp/kurashi/gomi/9/6/4394.html
- 門真市 粗大ごみの電話申込み: https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22406.html
- 門真市 粗大ごみインターネット申込み: https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22408.html

## 2. 確認したPDF・広報

- A地区ごみカレンダー 令和8(2026)年度版: https://www.city.kadoma.osaka.jp/material/files/group/20/A.pdf
- 広報かどまは検索しましたが、2026年12月から2027年1月の年末年始ごみ収集確定表は確認できていません。

## 3. 確認日

2026-05-25

## 4. 反映した情報

- 門真市の収集地区がA地区からF地区までであること。
- 大倉町がA地区に含まれること。
- A-F地区の基本収集曜日。
- ごみ出しは収集日の朝9時まで。
- 45L以下の無色透明または白色半透明袋。
- 普通ごみ、プラスチック製容器包装、びん・缶類、古紙・古布、小型ごみ、ペットボトル、粗大ごみの基本説明。
- 粗大ごみは受付センター申し込み、処理券が必要。

## 5. 反映しなかった情報

- 2026年12月から2027年1月の確定停止日・振替日。公式確定表を確認できていないため、確定例外としては登録していません。
- 公式PDF画像やアイコンの再配布。アプリ内は事実データとSF Symbols中心にしています。

## 6. 未確認の情報

- 2026年度末の年末年始ごみ収集確定表。
- A-F全PDFに同一の年末年始注意文があるかの個別目視確認。
- 台風・災害など臨時変更情報の将来発生分。

## 7. 年末年始・例外日の扱い

A地区PDFで12月・1月に収集日を変更する場合がある旨を確認しました。確定日が未確認のため、`exceptions` は空にし、`exceptionRules` に `confidence=needs_review` としてレビュー対象期間を登録しました。

## 8. special_rules.jsonへの反映内容

- `exceptions`: 空配列。未確認の停止・振替を確定登録しないため。
- `exceptionRules`: 2026-12-01 から 2027-01-31 を A-F 全地区の needs_review として登録。
- `sourceUrl`, `confirmedAt`, `confidence` を notice / exceptionRules に追加。

## 9. UI上で注意表示すべき内容

- 12月・1月は公式情報を確認すること。
- アプリの収集予定は2026年度マスタに基づくこと。
- 年末年始や災害時は通常曜日から変更される可能性があること。

## 10. 今後の公式確認TODO

- 2026年11月から12月に、門真市公式ページと広報かどまで年末年始収集表を確認する。
- 確定停止日・振替日が公開されたら `exceptions` に `confidence=confirmed` で登録する。
- A-F各PDFを個別に目視し、必要なら地区別の注意差分を記録する。
