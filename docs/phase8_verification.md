# Phase 8 Verification

## 1. 実行したコマンド

- `git diff --check`: 成功。CRLF変換警告のみ。
- `python Scripts\validate_data.py`: 成功。既存の低confidence/alias重複/年末年始needs_review警告44件は継続。
- `python Scripts\generate_master.py --check`: 成功。master/manifestは生成済みと一致。
- `python Scripts\run_quality_checks.py`: 成功。split/master/manifest、calendar smoke、search smoke、notification preview smokeを通過。
- `python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py`: 成功。
- `xcodebuild -version`: 失敗。Windows環境に `xcodebuild` がないためローカルXcodeビルドは不可。
- GitHub Actions `Build Unsigned iOS App` run `26430537617`: 成功。unsigned IPA artifact `KadomaGomi-unsigned-ipa` を生成。
- GitHub Actions `Deploy Master JSON to GitHub Pages` run `26430537619`: 成功。
- GitHub Actions `Validate Kadoma Data` run `26430610904`: 成功。
- GitHub Actions `Monitor Kadoma Official Sources` run `26430611090`: 成功。
- GitHub Pages `https://jankendo.github.io/kadoma-gomi-ios/manifest.json`: HTTP 200。`latestVersion=2026.04.01-af.4`、`municipalityCode=27223` を確認。

## 2. 成功した検証

- データ検証、master生成差分チェック、manifest SHA検証、検索/カレンダー/通知プレビューのPython smoke test。
- ホーム更新は既存 `MasterStore.refreshMaster()` を呼び出し、SHA-256検証後に成功時のみmasterを差し替える設計になっていることをコード確認。
- 通知テストidentifierが `dev-test-notification-` prefixで通常通知 `gomi_` と分離されていることをコード確認。
- ごみ分別カテゴリカードは固定高さで統一されるように変更。
- GitHub Actions上のmacOS build、IPA packaging、artifact upload。
- GitHub Pages manifest HTTP確認。

## 3. 失敗した検証

- Windows環境のためローカル `xcodebuild` は実行不可。

## 4. 未実施の検証

- Xcode Preview表示。
- Simulatorでの左右スワイプ操作。
- 実機での通知許可、通知拒否、5秒/10秒通知到達。
- VoiceOver実走査。
- Dynamic Type最大での実画面確認。

## 5. UI確認観点

- カレンダー左スワイプで翌月へ移動する。
- カレンダー右スワイプで前月へ移動する。
- ホームのごみ種別タップで分別詳細へ遷移する。
- カレンダーのごみ種別タップで分別詳細へ遷移する。
- ホーム更新ボタンで更新中/成功/失敗の1行表示が出る。
- ごみ分別カードの高さが揃う。
- 開発者用通知テストが通常設定から分離されている。

## 6. ビルド可否

ローカルWindowsでは未確認。GitHub ActionsのmacOS runnerでは成功。
