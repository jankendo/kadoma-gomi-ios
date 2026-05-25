# Phase 5 検証結果

最終更新: 2026-05-25

## 1. 実行したコマンド

```powershell
git diff --check
python Scripts\validate_data.py --split-only
python Scripts\generate_master.py --write
python Scripts\validate_data.py
python Scripts\generate_master.py --check
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
git push origin main
gh run view 26398859780 --json status,conclusion,displayTitle,url
gh workflow run source-monitor.yml
gh api repos/jankendo/kadoma-gomi-ios/actions/runs/26398859780/artifacts
gh run download 26398859780 -n KadomaGomi-unsigned-ipa -D build\phase5_artifacts
```

## 2. 成功した検証

- split JSON schema validation
- master JSON / manifest validation
- manifest SHA一致
- master生成
- 225品目維持
- A-F地区維持
- 大倉町1-20 -> A地区維持
- カテゴリ別 `disposalSteps` / `examples` 検証
- 品目別 `disposalSteps` / `sourceTitle` 検証
- カレンダースモークテスト
- 検索スモークテスト
- 通知プレビュースモークテスト
- Python構文チェック
- GitHub Actions Build Unsigned iOS App
- GitHub Actions Deploy Master JSON to GitHub Pages
- GitHub Actions Validate Kadoma Data
- GitHub Actions Source Monitor
- IPA artifact取得
- IPA内 `UIUserInterfaceStyle=Light`
- IPA内 bundled master `2026.04.01-af.4`, items=225, categories=9
- GitHub Pages remote manifest/master HTTP確認
- remote manifest SHA一致

## 3. 警告

- confidenceが低い一部品目はUIで公式確認推奨表示が必要
- alias重複は検索の表記ゆれ対応として許容。ただし今後、品目詳細で候補順位を継続確認する
- 年末年始ルールは `needs_review` のまま。確定例外日は未反映

## 4. 未検証項目

- Windows環境のためローカル `xcodebuild build` / `xcodebuild test` は未実施
- Simulator / 実機表示は未確認
- VoiceOver実走査は未確認
- Dynamic Type最大の実機確認は未実施

## 5. GitHub Actions結果

- Build Unsigned iOS App: success, run `26398859780`
- Deploy Master JSON to GitHub Pages: success, run `26398859779`
- Validate Kadoma Data: success, run `26398859713`
- Source Monitor: success, run `26398963248`

IPA artifact: `KadomaGomi-unsigned-ipa`

IPA SHA-256:

```text
d2131c42d88ba98b3aa63934bb39954c9874e148170a700ee39f52d686fb0df2
```

Remote master:

```text
version=2026.04.01-af.4
items=225
categories=9
sha_match=True
sha=a87a5875938479b48019bbd07ef0e8cf69ff367486623cc91dfa9c282ac7c332
```

## 6. ビルド可否

ローカルWindows環境では `xcodebuild` は実行不可。GitHub Actions macOS runnerでunsigned IPAビルド成功を確認した。
