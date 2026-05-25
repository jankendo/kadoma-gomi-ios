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

最終push後にGitHub Actions Build / Pages / Source Monitor、IPA artifact、manifest HTTP、SHA一致を確認して追記します。
