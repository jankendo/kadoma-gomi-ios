# Release Readiness

## 1. 現在の到達点

生活インフラ系アプリとして、A-F地区の基本収集ルール、生成可能なmaster、manifest SHA検証、検索正規化、通知予定プレビュー、主要Preview、CIデータ検証が整った。

## 2. App Store相当で確認が必要な項目

- 実機通知。
- VoiceOver実走査。
- Dynamic Type最大での実画面。
- iPhone SE、標準、Plus/Maxサイズの手動QA。
- PDF日付表・年末年始例外の人間レビュー。
- 非公式アプリ表記、公式リンク、免責文の最終確認。
- プライバシー表記。

## 3. リリース前ブロッカー

- 年末年始の実例外が未確定。
- 実機通知が未検証。
- VoiceOverの実走査が未検証。

## 4. 推奨リリース条件

1. GitHub Actions build/data-quality/pages/source-monitor がすべて成功。
2. 実機で通知許可/拒否/再設定を確認。
3. 公式PDFまたは広報で12月・1月例外をレビュー。
4. 主要端末サイズとDynamic Typeで画面崩れがないことを確認。

