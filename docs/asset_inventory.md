# Asset Inventory

## 1. 追加したアセット名

- `Assets.xcassets/AppIcon.appiconset`
- `Assets.xcassets/AccentColor.colorset`
- `Assets.xcassets/LaunchBackground.colorset`
- SF SymbolsベースのUIアイコン群

## 2. 用途

- `AppIcon.appiconset`: iOSホーム画面、Settings、Spotlight等で表示するアプリアイコン
- `AccentColor.colorset`: アプリ全体のアクセント色
- `LaunchBackground.colorset`: Launch Screen背景色
- SF Symbols: タブ、ホーム導線、ごみ種別、通知、地区、更新、注意、成功、エラー、検索、カレンダー

## 3. 配置場所

- `KadomaGomi/Resources/Assets.xcassets/AppIcon.appiconset`
- `KadomaGomi/Resources/Assets.xcassets/AccentColor.colorset`
- `KadomaGomi/Resources/Assets.xcassets/LaunchBackground.colorset`
- SF Symbolsはコード内で`Image(systemName:)`として使用

## 4. ライセンス・作成方法

- App Iconはこのリポジトリ内で自作生成したPNG。外部画像や著作権不明素材は使用していない。
- AccentColor / LaunchBackgroundは自作のasset catalog color。
- UIアイコンはApple SF Symbolsを使用。Appleプラットフォームアプリ内UI用途。

## 5. ライトモード対応

- App Iconは単体で視認できる固定色。
- AccentColorは明るく親しみやすいティール。
- LaunchBackgroundは薄い青緑系で、起動直後の白飛びを避ける。

## 6. ライトモード専用対応

- 第4フェーズでLaunchBackgroundのdark appearanceを削除。
- `UIUserInterfaceStyle=Light` とルートの `.preferredColorScheme(.light)` に合わせ、ライト専用で色を管理。
- UIアイコンはSF Symbolsを使い、色だけでなくラベルと併用する。
- App IconはiOS側の表示ルールに委ね、アプリ内UIでは使わない。

## 7. 使用画面

- App Icon: iOSシステム表示
- LaunchBackground: Launch Screen
- AccentColor: タブ、主要ボタン、状態表示
- SF Symbols:
  - ホーム: 地区、検索、カレンダー、通知、更新、注意
  - 分別検索: 検索、カテゴリ、ごみ種別
  - カレンダー: 予定、凡例、ごみ種別
  - 粗大ごみ: ソファ、電話、Web、チェックリスト
  - 設定: 地区、通知、更新、公式リンク、情報

## 補足

装飾だけの画像は追加していない。生活インフラ系アプリとして、読みやすさと操作理解に寄与するアセットに限定した。
## Phase 5 追加アセット

| 名称 | 用途 | 配置 | ライセンス/作成方法 | 使用画面 |
| --- | --- | --- | --- | --- |
| `AppIcon.guide` | 分別ガイド | `AppIcon.swift` | SF Symbols | ホーム、検索、ガイド |
| `AppIcon.steps` | 出し方ステップ | `AppIcon.swift` | SF Symbols | カテゴリ詳細、品目詳細 |
| `AppIcon.examples` | 代表例 | `AppIcon.swift` | SF Symbols | カテゴリ詳細 |
| `AppIcon.rinse` | 洗う/すすぐ | `AppIcon.swift` | SF Symbols | 出し方ステップ、品目詳細 |
| `AppIcon.remove` | 外す | `AppIcon.swift` | SF Symbols | 出し方ステップ、品目詳細 |
| `AppIcon.bundle` | しばる/まとめる | `AppIcon.swift` | SF Symbols | 出し方ステップ、品目詳細 |
| `AppIcon.reserve` | 予約 | `AppIcon.swift` | SF Symbols | 粗大ごみ、品目詳細 |
| `AppIcon.separate` | 分ける | `AppIcon.swift` | SF Symbols | 出し方ステップ、品目詳細 |

外部画像の無断取得は行っていない。画像生成は未実施で、将来の生成プロンプトは `phase5_assets_and_prompts.md` に記録した。
