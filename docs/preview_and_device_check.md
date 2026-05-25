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
