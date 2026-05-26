# Release Readiness Phase 3

## 現在の到達点

- 門真市限定方針を維持。
- A-F全地区の基本収集曜日を維持。
- 大倉町1-20 -> A地区プリセットを維持。
- master version は `2026.04.01-af.3`。
- 検索辞書は225件。
- 年末年始は未確認の確定日を登録せず、needs_review として扱う。
- Widget / App Shortcuts 用の読み取り専用層を追加。
- GitHub Actions build/pages/source-monitor は Phase 3 最終確認で成功。
- Phase 4でライトモード専用のポップなUIへ刷新。データ基盤は維持。

## リリース可否

コードとデータ検証は通過し、GitHub Actions `Build Unsigned iOS App` run `26387287807` で unsigned IPA の生成に成功しました。テスト配布用 unsigned IPA としては利用可能です。App Store 公開前には実機QA、VoiceOver、Dynamic Type最大、通知到達、公式年末年始確定表の確認が必要です。

## ブロッカー

- 2026年度末の年末年始確定表が未確認。
- 実機通知到達が未確認。
- VoiceOver実走査が未確認。
- Simulator / Xcode Preview 実画面確認が Windows 環境では未実施。
- Phase 4デザイン刷新後の実機ライト固定確認が未実施。

## 推奨リリース前作業

1. IPA を実機へインストールし、`release_qa_checklist.md` を実行する。
2. 通知許可/拒否/再設定を実機で確認する。
3. 年末年始確定情報が公開された時点で `special_rules.json` を更新する。
4. App Store公開に進む場合は署名、Bundle ID、プライバシー表記、非公式アプリ表記を最終確認する。
## Phase 5 追記

門真市限定方針、A-F地区、大倉町1-20プリセット、ライトモード専用UIは維持したまま、分別説明力を強化した。

リリース前に追加で確認すること:

- 共通PDFの品目別分別表をOCR + 人手レビューで完全照合する
- 実機で検索結果カードから品目詳細へ遷移できることを確認する
- ホームの出し方カードがiPhone SE相当とDynamic Type最大で読めることを確認する
- 公式確認推奨品目が断定表示になっていないことを確認する

## Phase 6 追記

第6フェーズでは、参考画像の思想をもとにシンプルな自治体アプリUIへ再設計した。リリース前確認では、ホームの直近7日リスト、検索空状態、ごみ分別タブのカテゴリ入口、カレンダー日付セル、設定画面の地区/通知導線を重点確認する。

データ基盤、A-F地区、大倉町1-20プリセット、225品目以上、master生成、schema validation、通知予定プレビューは維持している。実機ではVoiceOver、Dynamic Type最大、iPhone SE相当、通知許可/拒否、ライトモード固定を確認する。
