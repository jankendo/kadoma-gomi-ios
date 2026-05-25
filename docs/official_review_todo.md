# Official Review TODO

## 年末年始

- 2026年11月以降、門真市公式ページ「年末年始のごみ収集について」が公開されるか確認する。
- 広報かどま 2026年12月号、2027年1月号に年末年始ごみ収集表が掲載されるか確認する。
- 確定停止日・振替日が確認できたら `KadomaGomi/Resources/Data/special_rules.json` の `exceptions` に `confidence=confirmed` で追加する。
- confirmed 例外には `sourceUrl`、`confirmedAt`、`reason` を必ず入れる。

## PDF

- A-F地区PDFの12月・1月欄を個別確認する。
- PDF上の注意文が地区ごとに異なる場合は `exceptionRules` を地区別に分ける。

## 通知

- 年末年始の confirmed 例外を登録した後、通知予定プレビューに確定例外の注記が反映されることを確認する。

## リリース前

- master version、manifest SHA、Pages配信ファイル、アプリ同梱 master が一致することを確認する。
