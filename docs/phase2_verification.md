# Phase 2 Verification

## 1. 実行したコマンド

```powershell
python Scripts\validate_data.py --split-only
python Scripts\generate_master.py --write --generated-at 2026-05-25T11:45:00+09:00
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
git diff --check
```

GitHub Actionsで実行する予定:

```text
Validate Kadoma Data
Build Unsigned iOS App
Deploy Master JSON to GitHub Pages
Monitor Kadoma Official Sources
```

追加で実行:

```powershell
gh run watch 26380589274 --repo jankendo/kadoma-gomi-ios --exit-status
gh workflow run "Monitor Kadoma Official Sources" --repo jankendo/kadoma-gomi-ios --ref main
gh run watch 26380618375 --repo jankendo/kadoma-gomi-ios --exit-status
gh run download 26380589274 --repo jankendo/kadoma-gomi-ios --name KadomaGomi-unsigned-ipa --dir Artifacts/run-26380589274
tar -tf Artifacts\run-26380589274\KadomaGomi-unsigned.ipa
tar -xOf Artifacts\run-26380589274\KadomaGomi-unsigned.ipa Payload/KadomaGomi.app/initial_master_27223_2026.json
Invoke-WebRequest https://jankendo.github.io/kadoma-gomi-ios/manifest.json
Invoke-WebRequest https://jankendo.github.io/kadoma-gomi-ios/kadoma_27223_2026_master.json
```

## 2. 成功した検証

- 分割JSON schema validation。
- A-F地区ID存在チェック。
- 大倉町 -> A地区ルール存在チェック。
- カテゴリ/品目/地区/収集ルールID重複チェック。
- 存在しないカテゴリ参照・地区参照チェック。
- 日付形式チェック。
- master生成物一致チェック。
- docs master と manifest SHA一致チェック。
- A-F地区カレンダースモーク。
- 検索スモーク。
- Pythonスクリプト構文チェック。

## 3. 失敗した検証と修正

- 初回 `run_quality_checks.py` で manifest SHA不一致。原因はWindowsの改行変換。`generate_master.py` の書き出しをLF固定にして修正。
- 初回 `git diff --check` で分割JSON末尾の余分な空行を検出。末尾空行を削除して修正。
- 初回GitHub Actions build `26380547253` で `WasteSearchService.score` のローカル変数が同名メソッドを隠しSwift compile error。ローカル変数を `totalScore`、ヘルパーを `scoreText` に変更して修正。

## 4. 未検証項目

- ローカルXcode build。
- Xcode Preview実表示。
- Simulator起動・操作。
- 実機通知許可。
- VoiceOver実走査。
- Dynamic Type最大の実機表示。

## 5. 未検証理由

現在の作業環境はWindowsで、Xcode/iOS SDKが存在しない。XcodeBuildMCPもプロジェクト/Simulator defaultsが未設定で、ローカルSimulatorビルドは実行できなかった。

## 6. ビルド可否

ローカルWindowsでは不可。GitHub ActionsのmacOS runnerで `Build Unsigned iOS App` を実行し、成功を確認。

- Run: https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26380589274
- Artifact: `Artifacts/run-26380589274/KadomaGomi-unsigned.ipa`
- IPA SHA-256: `3264091EBB04985D83D4E6C1006C0F41EDB5B9AAC09E071DA9203AB903A12A78`
- IPA内master: `2026.04.01-af.2`, `areas=6`, `schedules=42`, `items=100`

## 7. データ検証可否

可。Python標準ライブラリだけで実行できる。

## 8. GitHub Actions結果

- `Validate Kadoma Data`: success, https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26380547242
- `Build Unsigned iOS App`: success, https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26380589274
- `Deploy Master JSON to GitHub Pages`: success, https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26380547248
- `Monitor Kadoma Official Sources`: success, https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26380618375

GitHub Pages確認:

- `manifest.json`: HTTP 200
- `kadoma_27223_2026_master.json`: HTTP 200
- Pages master: `version=2026.04.01-af.2`, `areas=6`, `items=100`
