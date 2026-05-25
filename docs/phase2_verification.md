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

ローカルWindowsでは不可。GitHub ActionsのmacOS runnerで `Build Unsigned iOS App` を実行して確認する。

## 7. データ検証可否

可。Python標準ライブラリだけで実行できる。

## 8. GitHub Actions結果

この節はpush後に更新する。

