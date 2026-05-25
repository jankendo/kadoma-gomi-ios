# Kadoma Gomi Mate

門真市 大倉町1-20を初期プリセットにしつつ、A-F地区の基本収集ルールに対応する非公式iOSごみ管理アプリです。

## 入っているもの

- SwiftUI iOSアプリ
- 大倉町1-20 -> A地区の住所判定
- 2026年度 A-F地区の収集ルール自動生成
- 今日・明日・次回表示
- 月間カレンダー
- 分別検索100品目
- 粗大ごみの電話/Web導線
- ローカル通知の再スケジュール
- 分割JSONからのmaster/manifest生成
- JSON schema/data quality検証
- GitHub Pages配信用 `manifest.json` / `master.json`
- GitHub Actionsによるunsigned IPAビルド
- 公式ページ更新検知ワークフロー

## Windowsでの作業方針

WindowsにはXcode/iOS SDKがないため、ローカルでは差分と構成確認だけを行い、実ビルドはGitHub ActionsのmacOS runnerで行います。

## GitHub Actions

- `Build Unsigned iOS App`: `KadomaGomi-unsigned.ipa` をartifactとして出力
- `Validate Kadoma Data`: schema、master生成、manifest SHA、検索/カレンダースモークを検証
- `Deploy Master JSON to GitHub Pages`: `docs/` のJSONをGitHub Pagesへ公開
- `Monitor Kadoma Official Sources`: 公式ページとPDFリンクのSHA-256差分を日次確認

## 注意

このアプリは門真市公式アプリではありません。情報は門真市公式ページをもとにしていますが、年末年始や災害時などの変更は必ず公式情報を確認してください。
