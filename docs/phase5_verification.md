# Phase 5 検証結果

最終更新: 2026-05-25

## 1. 実行したコマンド

作業途中時点:

```powershell
python Scripts\validate_data.py --split-only
python Scripts\generate_master.py --write
python Scripts\validate_data.py
python Scripts\run_quality_checks.py
python -m py_compile Scripts\validate_data.py Scripts\generate_master.py Scripts\run_quality_checks.py
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

## 3. 警告

- confidenceが低い一部品目はUIで公式確認推奨表示が必要
- alias重複は検索の表記ゆれ対応として許容。ただし今後、品目詳細で候補順位を継続確認する
- 年末年始ルールは `needs_review` のまま。確定例外日は未反映

## 4. 未検証項目

- Windows環境のためローカル `xcodebuild build` / `xcodebuild test` は未実施
- Simulator / 実機表示は未確認
- VoiceOver実走査は未確認
- Dynamic Type最大の実機確認は未実施

## 5. 後続検証予定

- GitHub Actionsでunsigned IPAビルド
- Pages deploy
- Source Monitor
- IPA artifact確認
- remote manifest/master HTTP確認

## 6. ビルド可否

このファイル作成時点では、ローカルWindows環境では直接ビルド不可。GitHub Actionsで最終確認する。
