# Accessibility Notes

## VoiceOver

- 今日/明日カード、収集イベント行、カレンダー日セル、検索結果カードは`accessibilityElement(children: .combine)`でまとまりとして読み上げる。
- カレンダー日セルは「日付、収集予定」の形式で明示的な`accessibilityLabel`を付与。
- ボタンには「設定を開く」「前の月」「次の月」など具体的なラベルを設定。
- SF Symbolsだけのボタンには意味を補足。

## Dynamic Type

- 主要テキストは`.largeTitle`、`.title2`、`.headline`、`.body`、`.callout`、`.footnote`などのテキストスタイルを使用。
- 検索結果や注意文は`fixedSize(horizontal: false, vertical: true)`で大きな文字でも縦に伸びる。
- カレンダーの小さなラベルは`minimumScaleFactor`を併用し、限界時は短い`shortName`で表示する。

## 色だけに依存しない表現

- ごみ種別は色に加えて、アイコン、短いラベル、正式名称を表示。
- 注意、成功、エラーは色に加えてSF Symbolと説明文を表示。
- カレンダーは色ラベルだけでなく凡例を表示。

## コントラスト

- 背景・カード・文字は`systemGroupedBackground`、`systemBackground`、`label`、`secondaryLabel`などの動的システム色を使用。
- 固定色は主にアクセントとごみ種別に限定し、背景全面には使わない。
- ダークモードではLaunchBackgroundとカード背景が動的に切り替わる。

## タップ領域

- 主要ボタン、チップ、入力欄、通知トグルは44pt以上を意識して`minimumTapTarget()`または`controlSize(.large)`を適用。

## Reduce Motion

- 派手な継続アニメーションは追加していない。
- オンボーディングのページ送りのみ短い標準的なアニメーション。必要なら将来`accessibilityReduceMotion`で無効化可能。

## エラー読み上げ

- 住所判定失敗、通知未許可、マスタ更新失敗はアイコンだけでなく日本語説明を表示し、読み上げ可能。

## 未検証

- Windows環境のため、VoiceOver実機走査、Dynamic Type最大サイズのスクリーンショット、Switch Control、Voice Controlは未検証。
- 次の実機QAで、ホーム、検索、カレンダー、設定、オンボーディングの主要フローをVoiceOverで通す必要がある。

