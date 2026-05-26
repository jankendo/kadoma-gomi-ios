# Preview and Device Check

## 1. 追加したPreview

- Home Light iPhone SE
- Home Light Dynamic Type
- Home Light Year End Notice
- Search Light Dynamic Type
- Search Hazard Result
- Search No Result
- Calendar Light iPhone SE
- Calendar Light Dynamic Type
- Calendar Light Year End
- Settings Light Dynamic Type
- Onboarding Light iPhone SE

## 2. 想定画面サイズ

- iPhone SE相当
- 393x852相当
- 430x932相当
- iPhone 15 Pro / Pro Max相当

## 3. Xcodeで確認する項目

- ホームで今日/明日の収集予定が最初に読めるか。
- カレンダーセルのラベルが小さい画面で潰れないか。
- 設定画面の地区PickerがDynamic Typeで読めるか。
- 通知予定プレビューが折り返して読めるか。
- iOS側がダークモードでもアプリがライト表示で固定されるか。
- ライト表示でカード、文字、警告色のコントラストが十分か。
- VoiceOverで収集カード、カレンダー日、検索結果、通知予定が意味の通る読み上げになるか。

## 4. 実機確認手順

1. GitHub Actionsのunsigned IPAを取得。
2. 署名なしインストール可能な検証環境、またはXcodeからDebugビルドで実機へ入れる。
3. 初回オンボーディングを完了。
4. 大倉町1-20プリセット、A-F地区手動選択、住所入力を確認。
5. 通知許可を許可/拒否の両方で確認。
6. 検索語 `PET`、`ぺっとぼとる`、`プラ`、`ダンボール` を確認。
7. Dynamic Type最大、ライトモード固定、VoiceOverを確認。

## 5. 未実施理由

現在の作業環境はWindowsで、ローカルXcode Preview、Simulator、実機通知は実行できない。ビルドはGitHub Actions macOS runnerで確認する。

## 6. Phase 3追記

実機QA手順は `docs/release_qa_checklist.md` に分離した。確認対象は iPhone SE相当、393x852、430x932、可能ならiPad。第4フェーズではライトモード専用のため、iOS側をダークにしてもアプリ内がライト固定になること、Dynamic Type最大、太字テキスト、コントラストを上げる、Reduce Motionを確認する。

通知の実機手順は `docs/device_notification_test_plan.md` に記録した。Windows環境では実機通知到達、VoiceOver実走査、Xcode Previewは未確認のまま残す。
## Phase 5 追加Preview確認

- `HomeTodayWasteGuideCard` 通常表示
- `WasteGuideOverviewSection` カテゴリ一覧
- `WasteItemDetailView` 注意品目詳細

実機では、検索結果から詳細画面への遷移、カテゴリ詳細のスクロール、Dynamic Type大での手順カード折り返しを確認する。

## Phase 6 Simple Preview

- Home Simple Default
- Home Simple iPhone SE
- Home Simple Dynamic Type Large
- Home Simple Year End Notice
- Search Simple Default
- Search Simple Result
- Search Simple Hazard Item
- Search Simple Dynamic Type Large
- Category Simple Grid
- Category Simple Detail
- Calendar Simple Default
- Calendar Simple iPhone SE
- Calendar Simple Dynamic Type Large
- Calendar Simple Year End Notice
- Settings Simple Default
- Settings Simple Dynamic Type Large
- Onboarding Simple
- Onboarding Simple iPhone SE

Phase 6ではDark Previewを追加しない。アプリはライトモード専用で、代わりに小型画面、Dynamic Type大、注意状態、空状態を重点確認する。

## Phase 7 Minimal Preview

- Home Weekly Simple Default
- Home Weekly Simple Today Collection
- Home Weekly Simple No Collection
- Home Weekly Simple iPhone SE
- Home Weekly Simple Dynamic Type Large
- Calendar Full Month Only Default
- Calendar Full Month Only iPhone SE
- Calendar Full Month Only Dynamic Type Large
- Calendar Full Month Only Multiple Items
- Calendar Full Month Only Year End Notice

Phase 7では、ホームに今週リストが主表示として出ること、カレンダーに月間グリッド以外の詳細カードが出ないことを重点確認する。
## Phase 8 Preview追加

- Home Weekly Category Tap
- Home Master Updating
- Home Master Update Success
- Home Master Update Failure
- Home iPhone SE
- Calendar Swipe Month Default
- Calendar Swipe Month Next Month
- Calendar Swipe Month Previous Month
- Calendar Category Tap Preview
- Calendar iPhone SE
- WasteGuide Uniform Cards
- WasteGuide Uniform Cards Long Names
- WasteGuide Category Detail
- Settings Normal User
- Settings Developer Mode
- Developer Notification Test
- Developer Pending Notifications

実機では、カレンダー左右スワイプの感度、カテゴリラベルのタップしやすさ、通知テスト到達、iPhone SE相当のカード高さを確認する。
