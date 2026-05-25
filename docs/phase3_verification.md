# Phase 3 Verification

## 1. 実行したコマンド

```powershell
git diff --check
python Scripts\validate_data.py
python Scripts\generate_master.py --check
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
Get-Command xcodebuild
gh run list --repo jankendo/kadoma-gomi-ios --limit 10
gh run download 26387287807 --repo jankendo/kadoma-gomi-ios --name KadomaGomi-unsigned-ipa --dir Artifacts\run-26387287807
```

## 2. 成功した検証

- `git diff --check`: 成功。空白エラーなし。
- `validate_data.py`: 成功。split JSON、master JSON、manifest を検証。
- `generate_master.py --check`: 成功。生成済み master / manifest と一致。
- `run_quality_checks.py`: 成功。データ品質、A-Fカレンダー、検索、通知プレビューのスモークテストを通過。
- `py_compile`: 成功。Pythonスクリプト構文エラーなし。
- manifest SHA は `docs/kadoma_27223_2026_master.json` と一致。
- GitHub Actions `Build Unsigned iOS App` run `26387287807`: 成功。
- GitHub Actions `Build Unsigned iOS App` run `26388195433`: 成功。検証ドキュメント更新後の最終pushでも unsigned IPA artifact 生成まで通過。
- GitHub Actions `Validate Kadoma Data` run `26387236105`: 成功。
- GitHub Actions `Deploy Master JSON to GitHub Pages` run `26387236106`: 成功。
- GitHub Actions `Deploy Master JSON to GitHub Pages` run `26388195383`: 成功。
- GitHub Actions `Monitor Kadoma Official Sources` run `26388244320`: 成功。
- GitHub Pages の `manifest.json` / `kadoma_27223_2026_master.json`: HTTP取得成功。manifest SHA と remote master SHA が一致。
- unsigned IPA artifact を `Artifacts\run-26387287807\KadomaGomi-unsigned.ipa` に取得。IPA内に `Info.plist`、実行ファイル、`Assets.car`、`initial_master_27223_2026.json`、分割JSONが含まれることを確認。

## 3. 失敗した検証

- 初回の `run_quality_checks.py` で「プラ」が普通ごみのプラスチック製品へ寄りすぎるランキングを検出。短い略語ではプラスチック製容器包装を優先するようスコア補正した。
- 初回の `run_quality_checks.py` で「リチュウム電池」が小型ごみの一般電池に寄りすぎるランキングを検出。リチウム/リチュウム/バッテリー系は注意品目を優先するようスコア補正した。
- 初回の GitHub Actions `Build Unsigned iOS App` run `26387236104` は Swift compile error で失敗。`WasteItem` の optional fallback 条件式を明示的に括弧付けして修正し、run `26387287807` で成功を確認した。

## 4. 失敗理由

辞書拡張により、一般語の「プラ」や「電池」が複数カテゴリに跨ったため。短い語はカテゴリ意図が強く、危険物語は注意品目優先にする必要があった。

## 5. 未検証項目

- Windows環境のため、ローカル `xcodebuild build`、`xcodebuild test`、Xcode Preview、Simulator、実機通知、VoiceOver実走査、Dynamic Type最大の実画面は未検証。
- Phase 3変更後の Source Monitor workflow は run `26388244320` で成功済み。

## 6. 今後必要な確認

- 実機で通知許可/拒否/再設定を確認する。
- `docs/release_qa_checklist.md` に沿って小型画面、Dynamic Type最大、VoiceOverを確認する。
- 2026年11月以降に年末年始確定表を確認する。

## 7. ビルド可否

ローカルWindowsでは不可。`Get-Command xcodebuild` で `xcodebuild` が存在しないことを確認。GitHub Actions macOS runner の `Build Unsigned iOS App` run `26387287807` で成功。

## 8. テスト可否

Swift unit testターゲットは未作成。Pythonベースのデータ/生成/検索/カレンダー/通知プレビュー検証を実施済み。

## 9. Phase 3データ結果

- master version: `2026.04.01-af.3`
- areas: 6
- schedules: 42
- items: 225
- confirmed exceptions: 0
- exceptionRules: 1
- manifest SHA: `f30e74e7747372ec0d84062c4cf0ee11da195c7591dd985aa7da2c0cff69cfcf`
- remote manifest/master SHA一致: 成功
- IPA SHA-256: `3dd8ba69f46822197cbf02359aa01882a5bc05be447af36981d778bc1cd88b9f`
- IPA同梱master: version `2026.04.01-af.3`、areas 6、schedules 42、items 225、confirmed exceptions 0、exceptionRules 1
