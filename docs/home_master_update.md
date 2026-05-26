# Home Master Update

## 1. 目的

ホーム右上の更新ボタンから、その場で門真市ごみ収集マスタを確認・更新できるようにする。

## 2. 更新フロー

1. `settings.remoteManifestURL` から manifest を取得する。
2. manifest の `masterUrl` から master JSON を取得する。
3. master JSON の SHA-256 を manifest の `sha256` と照合する。
4. JSON decode を行う。
5. municipalityCode が `27223` であることを確認する。
6. 地区、カテゴリ、品目IDの重複と参照整合性を確認する。
7. 成功時だけ `MasterStore.master` とローカルキャッシュを更新する。
8. 更新後に通知を直近60日分で再設定する。

## 3. UI状態

- 更新中: 「データを更新しています...」
- 更新成功: 「ごみ収集データを更新しました」
- 最新版: 「すでに最新のデータです」
- 失敗: 「データを更新できませんでした。通信状況を確認して、もう一度お試しください。」

## 4. 安全設計

SHA-256不一致、門真市以外のmunicipalityCode、重複ID、不正なカテゴリ参照がある場合はマスタを適用しない。既存のキャッシュは保持するため、オフライン時もアプリは利用できる。

## 5. 通知との関係

master更新に成功した場合は、既存の `MasterStore.rescheduleNotifications()` を通じて通知を再設定する。通知再設定に失敗した場合は `syncMessage` へ失敗理由が残る。
