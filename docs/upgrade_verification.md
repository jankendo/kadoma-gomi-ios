# Upgrade Verification

## 1. 実行したコマンド

```powershell
git diff --check
```

```powershell
python - <<'PY'
import json, plistlib, hashlib
from pathlib import Path
for p in list(Path('KadomaGomi/Resources').rglob('*.json')) + [Path('docs/manifest.json'), Path('docs/kadoma_27223_2026_master.json')]:
    json.loads(p.read_text(encoding='utf-8'))
plistlib.loads(Path('KadomaGomi/Info.plist').read_bytes())
master_hash=hashlib.sha256(Path('docs/kadoma_27223_2026_master.json').read_bytes()).hexdigest()
manifest=json.loads(Path('docs/manifest.json').read_text(encoding='utf-8'))
assert master_hash == manifest['sha256']
PY
```

```powershell
python - <<'PY'
from pathlib import Path
pbx=Path('KadomaGomi.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
for swift in Path('KadomaGomi').rglob('*.swift'):
    assert swift.name in pbx
for required in ['Assets.xcassets','garbage_categories.json','garbage_items.json','collection_areas.json','collection_schedule.json','special_rules.json']:
    assert required in pbx
PY
```

```powershell
python - <<'PY'
# A地区の主要日付期待値チェック
PY
```

```powershell
gh run watch 26379716315 --repo jankendo/kadoma-gomi-ios --exit-status
gh run download 26379716315 --repo jankendo/kadoma-gomi-ios --name KadomaGomi-unsigned-ipa --dir Artifacts/run-26379716315
```

```powershell
Invoke-WebRequest -UseBasicParsing -Uri "https://jankendo.github.io/kadoma-gomi-ios/manifest.json"
Invoke-WebRequest -UseBasicParsing -Uri "https://jankendo.github.io/kadoma-gomi-ios/kadoma_27223_2026_master.json"
```

## 2. 成功した検証

- JSON parse: 成功
- Info.plist parse: 成功
- manifest SHA-256とmaster JSON SHA-256一致: 成功
- Xcode projectのSwiftファイル参照: 成功
- Asset Catalog参照: 成功
- 分割JSON参照: 成功
- App Icon PNG 18枚のPNGヘッダー確認: 成功
- A地区カレンダー期待値:
  - 2026-05-25: プラスチック製容器包装
  - 2026-05-26: 普通ごみ
  - 2026-05-06: ペットボトル
  - 2026-05-13: 小型ごみ
  - 2026-05-20: ペットボトル
  - 2026-05-27: 古紙・古布
  - 2026-05-28: びん・缶類、粗大ごみ
  - 2026-05-29: 普通ごみ
  - 2026-05-30/31: なし
- 検索種データ:
  - ペット / PET / ボトル / スプレー缶 / フライパン / ソファで候補あり
- GitHub Actions unsigned iOS build: 成功
- IPA artifact取得: 成功
- IPA内検査:
  - `Payload/KadomaGomi.app/Info.plist`: あり
  - `Payload/KadomaGomi.app/KadomaGomi`: あり
  - `Payload/KadomaGomi.app/initial_master_27223_2026.json`: あり
  - `Payload/KadomaGomi.app/Assets.car`: あり
  - 分割JSON 5ファイル: あり
- GitHub Pages:
  - `manifest.json`: HTTP 200
  - `kadoma_27223_2026_master.json`: HTTP 200、100品目

## 3. 失敗した検証

- 初回のApp Icon PNG件数チェックで、生成ファイル名が`_png`になっていたため失敗。

## 4. 失敗理由

- 生成スクリプトのファイル名整形で`.png`拡張子まで置換していた。

## 5. 未検証項目

- Windows環境のため、ローカルXcode build、Preview表示、Simulator操作、実機通知許可、VoiceOver実走査、Dynamic Type最大サイズでの実画面確認は未実施。
- iOSの通知権限ダイアログとiOS設定遷移は実機/Simulatorで追加確認が必要。

## 6. 今後必要な確認

- iPhone SE相当、393x852、430x932での表示確認
- VoiceOverでホーム、検索、カレンダー、設定、オンボーディングを通す
- Dynamic Type Extra Extra Extra Largeでのテキスト折返し確認
- 通知許可拒否後のiOS設定導線確認
- 年末年始例外が追加されたマスタの差分更新確認

## 7. ビルド可否

可。GitHub Actions macOS runnerでRelease / iphoneos / unsigned build成功。

Run:

- https://github.com/jankendo/kadoma-gomi-ios/actions/runs/26379716315

Artifact:

- `Artifacts/run-26379716315/KadomaGomi-unsigned.ipa`

SHA-256:

- `204ce7d1c88c49ee1268549af644ba861eadfc75e792761d43edb08e41aa8981`

## 8. テスト可否

自動テストターゲットは未作成。今回は静的検証、データ検証、GitHub Actionsビルド、artifact検査を実施。

## 9. Phase 2追記

第2フェーズでは `Scripts/run_quality_checks.py` を追加し、schema validation、生成物一致、manifest SHA、A-F地区カレンダースモーク、検索スモークをローカル/CIで確認できるようにした。Swiftのローカルビルドは引き続きWindowsでは不可のため、GitHub ActionsのmacOS runnerを正とする。
