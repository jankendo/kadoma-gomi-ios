# Phase 7 Verification

## 1. 実行したコマンド

```powershell
git diff --check
python Scripts\validate_data.py
python Scripts\generate_master.py --check
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
xcodebuild build
gh run view 26429032122 --json status,conclusion,url,jobs
gh run view 26429032061 --json status,conclusion,url,jobs
gh run download 26429032122 --dir .\artifacts\phase7-build
gh workflow run source-monitor.yml --ref main
gh run view 26429084471 --json status,conclusion,url,jobs
```

## 2. 成功した検証

- `git diff --check`: 成功。
- 旧カレンダー詳細コンポーネント、凡例、リスト表示、Homeの今日カード/クイックアクション/DataStatus参照が残っていないことを `rg` で確認。
- `python Scripts\validate_data.py`: 成功。既存のlow confidence、alias重複、年末年始needs_reviewは警告として出力。
- `python Scripts\generate_master.py --check`: 成功。master/manifestは最新。
- `python Scripts\run_quality_checks.py`: 成功。data validation、calendar smoke、search smoke、notification preview smokeを通過。
- `python -m py_compile ...`: 成功。
- GitHub Actions `Build Unsigned iOS App`: 成功。run `26429032122`。
- GitHub Actions `Deploy Master JSON to GitHub Pages`: 成功。run `26429032061`。
- GitHub Actions `Monitor Kadoma Official Sources`: 成功。run `26429084471`。
- IPA artifact: `KadomaGomi-unsigned.ipa` を取得。サイズ `681355` bytes。`Payload/KadomaGomi.app/` を確認。
- GitHub Pages manifest: HTTP 200、`latestVersion=2026.04.01-af.4`、SHA-256一致。

## 3. 失敗/未実施の検証

- `xcodebuild build`: Windows環境では `xcodebuild` が存在しないため実行不可。代替としてGitHub Actions macOS runnerでビルド成功を確認した。
- `xcodebuild test`: Windows環境のため未実施。
- Xcode Preview / Simulator / 実機表示: Windows環境のため未実施。

## 4. UI観点の確認

- Homeは地区帯と7日リスト中心になり、今日カード、クイックアクション、データ状態カードを削除。
- Calendarは表示切替、凡例カード、選択日詳細カード、下部リストを削除し、月間グリッド中心に変更。
- Home/CalendarともにiPhone SE相当とDynamic Type LargeのPreview名を整備。

## 5. 未検証項目

- VoiceOver実走査。
- Dynamic Type最大の実画面確認。
- iPhone SE相当、393x852、430x932でのSimulator/実機目視。
- 通知許可/拒否/再設定と通知到達。

## 6. ビルド可否

GitHub Actions macOS runnerでビルド成功。unsigned IPA artifact生成成功。
