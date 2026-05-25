# Repository Audit

## 1. アプリ概要

Kadoma Gomi Mate / かどまごみナビは、門真市 大倉町1-20 / A地区を初期対象にした非公式のiOSごみ管理アプリ。今日・明日・次回の収集日、月間カレンダー、分別検索、粗大ごみ案内、通知、マスタ更新を扱う。

## 2. 技術スタック

- UI: SwiftUI
- 永続化: SwiftDataモデル定義あり。ただし主要設定とマスタキャッシュはUserDefaults。
- 通知: UserNotifications
- 通信: URLSession
- JSON: Codable
- 暗号ハッシュ: CryptoKit SHA-256
- CI: GitHub Actions macOS runnerによるunsigned IPAビルド
- 配信: GitHub Pagesの`manifest.json` / `master.json`
- 依存ライブラリ: 外部Swift Packageなし

## 3. ディレクトリ構成

- `KadomaGomi/App`: App entry pointとTabView
- `KadomaGomi/Core/Models`: マスタ、収集イベント、SwiftDataモデル
- `KadomaGomi/Core/Services`: 住所判定、カレンダー生成、マスタ同期、通知、検索
- `KadomaGomi/Core/Utilities`: 日付、色変換
- `KadomaGomi/Features`: Home, Calendar, Search, BulkyWaste, Settings
- `KadomaGomi/Resources`: 初期マスタJSON
- `docs`: Pages配信JSON、監視ベースライン、開発ドキュメント
- `.github/workflows`: iOSビルド、Pagesデプロイ、公式ソース監視
- `Scripts`: 公式ページ/PDFリンクの差分検知スクリプト

## 4. 主要画面一覧

- ホーム: 今日・明日・次回、年末年始注意
- カレンダー: 月表示
- 分別検索: テキスト検索と結果一覧
- 粗大ごみ: 電話/Web申込導線
- 設定: 地区、通知、マスタ更新、公式情報リンク

## 5. 主要機能一覧

- 大倉町1-20 / 大倉町 -> A地区判定
- 2026年度A地区収集ルールの自動生成
- 第n水曜ルール
- 例外日のnote/add/cancel構造
- 分別検索100品目
- 直近60通知の再登録
- remote manifestのversion比較、master取得、SHA-256検証
- GitHub Pagesによるマスタ配信
- 公式ページ/PDF SHA-256監視

## 6. 既存データ構造

- `MunicipalityMaster`: 市区町村マスタ全体
- `CollectionArea`: 地区、町名、収集ルール、例外
- `ScheduleRule`: weekly / monthlyNthWeekday / specificDates
- `WasteCategory`: ごみ種別、表示名、色、アイコン、注意
- `WasteItem`: 品目名、表記ゆれ、カテゴリ、キーワード、注意
- `Notice`: 年末年始などの注意
- `UserSettings`: 住所、地区、通知、remote manifest URL

## 7. 既存アセット一覧

- 専用画像・App Icon・Asset Catalogなし
- UIアイコンはSF Symbolsのみ
- `Info.plist`は空の`UILaunchScreen`定義あり

## 8. 現在のUI/UXの問題点

- ホームの今日/明日の視認性はあるが、主情報の強弱が弱い
- ごみ検索は候補、カテゴリ絞り込み、手順表示、関連案内が弱い
- カレンダーは色ラベル中心で、リスト表示や凡例がない
- 地区設定はForm内に埋もれており、初回案内がない
- 通知許可状態や未許可時の対処が見えない
- マスタ更新の状態が成功/失敗/読み込みで分かれない
- 空状態とエラー状態が画面ごとに統一されていない
- オンボーディングがない
- 公式アプリではない注意はあるが、信頼感のある情報設計に未整理

## 9. 現在のコード品質の問題点

- 画面ごとにカード、バッジ、行表示の実装が重複し始めている
- 色、角丸、余白、影、タイポグラフィが散在
- `HomeView`と`CalendarView`にローカルなイベント表示部品があり再利用しづらい
- `UserSettings`は将来の設定追加時に既存UserDefaultsデコード互換が壊れやすい
- `NotificationService`は通知許可拒否をUIへ返せない
- App Icon/Asset Catalogがない
- Previewが未整備

## 10. 壊してはいけない既存機能

- 大倉町 / 大倉町1-20 -> A地区
- A地区の曜日ルール
- 粗大ごみは木曜表示だが要予約として扱うこと
- 年末年始は例外マスタ/公式確認を優先すること
- `manifest.json` -> `master.json` -> SHA-256検証の更新経路
- GitHub Actionsのunsigned IPAビルド
- GitHub Pages配信URL
- 公式ソース監視スクリプト

## 11. 改修方針

- デザインシステムと共通UI部品を追加し、主要画面を段階的に置き換える
- `UserSettings`を後方互換のあるCodableにする
- オンボーディング、地区設定、通知許可、空/エラー/読み込み状態を明示する
- 検索とカレンダーは既存データを使いながらUI/UXだけを強化する
- データは現行monolithic masterを壊さず、分割管理用JSONを追加する
- SF Symbolsと自作App Iconのみを使い、著作権不明素材は入れない

## 12. 作業上のリスク

- WindowsローカルではXcodeビルド/Preview/Simulator実行不可。最終確認はGitHub Actions macOS runnerで行う。
- 手書きXcode projectのため、新規Swift/asset追加時は`project.pbxproj`の参照漏れが起きやすい。
- 通知許可状態は実機/Simulatorでの確認が必要。
- 公式PDFの実日付例外は完全自動化していないため、年末年始は引き続きレビューが必要。

