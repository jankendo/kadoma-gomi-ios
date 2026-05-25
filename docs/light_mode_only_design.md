# Light Mode Only Design

## 1. 方針

このアプリは第4フェーズからライトモード専用です。高齢者や初心者が毎日同じ見え方で確認できるよう、配色・カード・ごみ種別チップをライト背景に最適化します。

## 2. 設定

- `KadomaGomi/Info.plist`: `UIUserInterfaceStyle` を `Light` に設定。
- `KadomaGomiApp`: ルートに `.preferredColorScheme(.light)` を設定。
- `LaunchBackground.colorset`: dark appearance を削除。
- SwiftUI Preview: Dark PreviewをLight Dynamic Type / iPhone SE / 年末年始注意Previewへ置換。

## 3. ダークモードを廃止した理由

ごみ収集日アプリでは、色・ラベル・アイコンの一貫性が信頼性に直結します。ライト専用にすることで、カレンダーの小さなチップや注意表示の視認性を安定させ、実機確認前の表示差分を減らします。

## 4. アクセシビリティ維持

ライト専用でも、Dynamic Type、VoiceOver、44pt以上のタップ領域、色だけに依存しない表現、十分なコントラストは維持します。Dark Mode非対応はアクセシビリティ低下ではなく、表示安定性のための製品判断として扱います。

## 5. QA観点

- iOS設定をDarkにしてもアプリ内がLightで表示される。
- 文字サイズ最大でも重要情報が読める。
- カレンダーの色チップに短いラベルとアイコンがある。
- 注意表示が薄すぎず、本文が読み取れる。
