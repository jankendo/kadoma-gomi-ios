# Master Generation

## 1. 目的

分割JSONを唯一の編集元にし、アプリ同梱master、GitHub Pages配信用master、manifestを同じ手順で生成する。手作業コピーによる差分、SHA不一致、A-F地区の抜けを防ぐ。

## 2. 入力ファイル

- `KadomaGomi/Resources/Data/garbage_categories.json`
- `KadomaGomi/Resources/Data/garbage_items.json`
- `KadomaGomi/Resources/Data/collection_areas.json`
- `KadomaGomi/Resources/Data/collection_schedule.json`
- `KadomaGomi/Resources/Data/special_rules.json`

## 3. 出力ファイル

- `KadomaGomi/Resources/initial_master_27223_2026.json`
- `docs/kadoma_27223_2026_master.json`
- `docs/manifest.json`
- `build/master_diff.txt`

## 4. 実行方法

```powershell
python Scripts\validate_data.py --split-only
python Scripts\generate_master.py --write --generated-at 2026-05-25T11:45:00+09:00
python Scripts\run_quality_checks.py
```

CIやPR確認では生成物の差分を許容しない。

```powershell
python Scripts\generate_master.py --check
```

## 5. バージョンとSHA

現在のmaster versionは `2026.04.01-af.2`。manifestの `sha256` は `docs/kadoma_27223_2026_master.json` の実バイト列から生成する。WindowsでもSHAがずれないよう、生成スクリプトはLFで書き出す。

## 6. 公式情報との関係

A-F地区の町名、曜日ルール、朝9時までの案内は門真市公式の地区別ごみカレンダーページを確認元にする。分別カテゴリと注意文は門真市公式の「ごみの出し方・分け方」を確認元にする。

## 7. レビューが必要な範囲

12月・1月の年末年始変更、PDF日付表の例外、災害・台風などの臨時変更は自動生成だけで確定しない。`special_rules.json` の notice と manifest `requiresReview` で公式確認を促す。

## 8. 失敗時の見方

- `validate_data.py`: JSON型、必須項目、参照整合性、重複、日付形式の不備。
- `generate_master.py --check`: 生成物がコミット済みファイルと一致しない。
- `run_quality_checks.py`: schema、master生成、manifest SHA、カレンダー、検索のスモークテスト。

## 9. Phase 3追記

`MASTER_VERSION` は `2026.04.01-af.3`。生成 master には `exceptionRules` を含める。これは未確認の年末年始レビュー対象期間を UI / Widget / App Shortcuts で参照しやすくするための読み取りデータであり、確定例外ではない。

Phase 3 の生成手順:

```powershell
python Scripts\validate_data.py --split-only
python Scripts\generate_master.py --write --generated-at 2026-05-25T12:40:00+09:00
python Scripts\run_quality_checks.py
```

`special_rules.exceptions` は confirmed のみ。未確認の年末年始日付は `exceptionRules` の `needs_review` に留める。
