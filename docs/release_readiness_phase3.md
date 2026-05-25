# Release Readiness Phase 3

## 現在の到達点

- 門真市限定方針を維持。
- A-F全地区の基本収集曜日を維持。
- 大倉町1-20 -> A地区プリセットを維持。
- master version は `2026.04.01-af.3`。
- 検索辞書は225件。
- 年末年始は未確認の確定日を登録せず、needs_review として扱う。
- Widget / App Shortcuts 用の読み取り専用層を追加。

## リリース可否

コードとデータ検証が通り、GitHub Actions build が成功すれば、テスト配布用 unsigned IPA としては利用可能です。App Store 公開前には実機QA、VoiceOver、Dynamic Type最大、通知到達、公式年末年始確定表の確認が必要です。

## ブロッカー

- 2026年度末の年末年始確定表が未確認。
- 実機通知到達が未確認。
- VoiceOver実走査が未確認。
- Simulator / Xcode Preview 実画面確認が Windows 環境では未実施。

## 推奨リリース前作業

1. GitHub Actions build の成功を確認する。
2. IPA を実機へインストールし、`release_qa_checklist.md` を実行する。
3. 年末年始確定情報が公開された時点で `special_rules.json` を更新する。
4. Pages manifest/master の HTTP 200 と SHA 一致を確認する。
