# Preview and Device Check

## 1. 追加したPreview

- Home iPhone SE
- Home Dark Large Type
- Search Dark Large Type
- Calendar iPhone SE
- Calendar Dark Large Type
- Settings Dark Large Type

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
- ダークモードのカード、文字、警告色のコントラスト。
- VoiceOverで収集カード、カレンダー日、検索結果、通知予定が意味の通る読み上げになるか。

## 4. 実機確認手順

1. GitHub Actionsのunsigned IPAを取得。
2. 署名なしインストール可能な検証環境、またはXcodeからDebugビルドで実機へ入れる。
3. 初回オンボーディングを完了。
4. 大倉町1-20プリセット、A-F地区手動選択、住所入力を確認。
5. 通知許可を許可/拒否の両方で確認。
6. 検索語 `PET`、`ぺっとぼとる`、`プラ`、`ダンボール` を確認。
7. Dynamic Type最大、ダークモード、VoiceOverを確認。

## 5. 未実施理由

現在の作業環境はWindowsで、ローカルXcode Preview、Simulator、実機通知は実行できない。ビルドはGitHub Actions macOS runnerで確認する。

