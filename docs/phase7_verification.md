# Phase 7 Verification

## 1. 実行予定コマンド

```powershell
git diff --check
python Scripts\validate_data.py
python Scripts\generate_master.py --check
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
xcodebuild build
```

## 2. 作業中確認

- `git diff --check`: 成功。
- 旧カレンダー詳細コンポーネント、凡例、リスト表示、Homeの今日カード/クイックアクション/DataStatus参照が残っていないことを `rg` で確認。

## 3. 最終検証

最終検証結果は作業完了時に追記する。

## 4. 未検証項目

- Windows環境のためXcode Preview、Simulator、実機表示はローカル未確認。
- VoiceOver、Dynamic Type最大、通知実到達は実機QAが必要。
