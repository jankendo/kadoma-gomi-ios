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
- AccentColorは公共サービス系の落ち着いた青緑。
- LaunchBackgroundは薄い青緑系で、起動直後の白飛びを避ける。

## 6. ダークモード対応

- LaunchBackgroundはdark appearanceを定義済み。
- UIアイコンはSwiftUIのforegroundStyleとセマンティックカラーで自動追従。
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

