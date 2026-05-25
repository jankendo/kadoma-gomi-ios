# Phase 4 Verification

## 1. 実行予定コマンド

```powershell
git diff --check
python Scripts\validate_data.py
python Scripts\generate_master.py --check
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
```

## 2. ローカル検証結果

作業中検証では `validate_data.py`、`generate_master.py --check`、`run_quality_checks.py` が通過しています。低信頼品目、alias重複、Dec/Jan needs_review は意図的な警告です。

- `git diff --check`: 成功。CRLF警告のみ。
- `python Scripts\validate_data.py`: 成功。44 warningsは既知の低信頼品目/alias重複/needs_review。
- `python Scripts\generate_master.py --check`: 成功。生成済みmaster/manifestと一致。
- `python Scripts\run_quality_checks.py`: 成功。データ品質、カレンダー、検索、通知プレビューのスモークを通過。
- `python -m py_compile ...`: 成功。

## 3. UI検証観点

- Light Mode固定。
- Home Light iPhone SE。
- Home Light Dynamic Type。
- Home Light Year End Notice。
- Calendar Light iPhone SE。
- Calendar Light Dynamic Type。
- Calendar Light Year End。
- Search Hazard Result。
- Search No Result。
- Settings Light Dynamic Type。
- Onboarding Light iPhone SE。

## 4. 未検証項目

Windows環境のため、ローカル `xcodebuild`、Xcode Preview実描画、Simulator、実機通知、VoiceOver実走査は未検証です。GitHub Actions macOS runnerでbuildを確認します。

## 5. 最終結果

- 初回GitHub Actions Build run `26389067042`: 失敗。`AppColor.categoryBackground` で引数名が関数名を隠していたためSwift compile error。
- 修正後GitHub Actions Build run `26389118622`: 成功。Release / iphoneos / unsigned IPA artifact生成まで通過。
- GitHub Actions Pages run `26389067001`: 成功。
- GitHub Actions Source Monitor run `26389174701`: 成功。
- GitHub Pages manifest/master: HTTP 200、manifest SHA と remote master SHA が一致。
- remote master: version `2026.04.01-af.3`、areas 6、items 225、exceptionRules 1。
- unsigned IPA: `Artifacts\run-26389118622\KadomaGomi-unsigned.ipa`。
- IPA SHA-256: `e778b3ea6d320c279b1e2152bdab4f51b7e1624ddf46dbdf7fdb9e6494430198`。
- IPA内 `Info.plist`: `UIUserInterfaceStyle=Light`。
- IPA同梱master: version `2026.04.01-af.3`、areas 6、items 225、exceptionRules 1。
