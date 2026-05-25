# UX Research Notes

## Phase 4方針更新

第4フェーズでは、Dark Mode対応よりもライト表示の安定性を優先し、アプリをライトモード専用にした。以下の初期調査メモにはDark Mode対応前提の記述が残るが、現在の実装方針は `docs/light_mode_only_design.md` を正とする。

## 1. 調査できた情報

- 門真市公式「地区別ごみカレンダー」は2026年03月30日更新。A地区に大倉町が含まれ、普通ごみは火・金、プラスチック製容器包装は月、びん・缶類と粗大ごみは木、古紙古布は第4水曜、小型ごみは第2水曜、ペットボトルは第1・第3水曜。収集日の朝9時までに出す案内がある。
- 門真市公式「ごみの出し方・分け方」は2026年03月30日更新。袋は45L以下の無色透明または白色半透明、普通ごみ、プラ容器、びん・缶、古紙・古布、小型ごみ、ペットボトル、粗大ごみの注意が確認できた。
- Apple HIGでは、Tab barは主要セクション間の移動、Searchは見つけたいものを素早く探すための入口、Dark Modeはシステム背景色を優先、通知許可はUserNotificationsの権限要求フローに従う設計が重要。
- Appleのアクセシビリティ基準では、VoiceOverで見えている重要情報がラベル/説明として伝わること、要素種別・状態・値が分かること、Larger Text / Dark Interface / 色だけに依存しない表現 / コントラスト / Reduced Motionが評価対象になる。

## 2. 調査できなかった情報

- 門真市公式PDFの全月日付表をOCRで完全抽出するところまでは実施していない。
- App Storeにある他自治体ごみアプリの詳細な操作分析は実施していない。
- 実機での高齢者ユーザーテスト、VoiceOver実走査、Dynamic Type最大サイズのスクリーンショット確認はWindows環境では未実施。

## 3. Apple HIGから反映すべき原則

- 主要機能はTabViewで安定して移動できるようにする。
- 検索は下部タブまたは画面内検索で常に見つけやすくする。
- 標準のNavigationStack、Form、List、Link、Button、SF Symbolsを優先する。
- Dark Modeは固定色ではなくシステム背景・セマンティックカラーを使う。
- 通知許可は目的を説明してから要求し、拒否時はiOS設定への導線を出す。

## 4. 生活インフラ系アプリに必要なUX原則

- 最初の3秒で今日/明日の行動が分かる。
- データの出典、更新日、非公式アプリであることを明示する。
- 迷ったときの次アクションを常に表示する。
- 平常時は軽く、例外時ははっきり注意を出す。
- 装飾より読みやすさと信頼感を優先する。

## 5. ごみ分別アプリに必要なUX原則

- 「いつ出すか」と「どう出すか」を分けて見せる。
- 粗大ごみは単なる曜日ではなく予約・処理券・期限を強調する。
- 検索結果はカテゴリ名だけでなく、注意と手順を添える。
- 表記ゆれ、ひらがな/カタカナ、略語に強くする。
- 年末年始や例外日は通常ルールと同じ見た目にしない。

## 6. 高齢者・初心者向けに必要な配慮

- 大きめの文字、十分な余白、44pt以上のタップ領域。
- 「設定」「更新」などの結果を成功/失敗で明示する。
- 色に加えてアイコン、短いラベル、説明文を併用する。
- 入力欄には例とエラー対処を表示する。
- 専門語を避け、「朝9時まで」「袋」「洗う」「要予約」のような行動語を使う。

## 7. カレンダーUIの改善方針

- 月表示に加え、直近予定リストを同画面で表示する。
- 今日を明確に強調する。
- 色だけでなく短いごみ種別ラベルとSF Symbolを使う。
- 凡例を追加する。
- 年末年始注意を画面下部で常時参照可能にする。

## 8. 検索UIの改善方針

- SwiftUIの`.searchable`を使い、検索欄を画面標準位置に置く。
- カテゴリ絞り込みチップを追加する。
- よく使う品目と候補を空入力時に表示する。
- 検索結果なしでは公式確認・語句変更・カテゴリ確認を案内する。
- 結果カードにカテゴリ、注意、関連名、公式確認の必要度を表示する。

## 9. 通知UXの改善方針

- 通知許可状態を設定画面で見せる。
- 前日/当日朝、時刻、カテゴリ別ON/OFFを分ける。
- 未許可時は「通知を許可」または「iOS設定を開く」を表示する。
- 直近60日分のみ予約する既存設計を維持する。

## 10. 地区設定UXの改善方針

- 初回オンボーディングで大倉町1-20/A地区を明示する。
- 設定画面では現在地区、住所入力、プリセット適用、変更の影響を1カードにまとめる。
- 判定できない入力は原因と例を表示する。
- 将来の全地区対応に備え、町名/番地範囲ルールをデータとして残す。

## 11. 空状態・エラー状態の改善方針

- 空状態は「何がないか」ではなく「次に何をするか」を表示する。
- 通信エラーは再試行、公式ページ確認、時間をおいて再試行を案内する。
- 読み込み中はProgressViewと短文で目的を伝える。
- 成功時は目立ちすぎないバナーで結果を伝える。

## 12. このアプリに導入する具体的改善

- DesignSystem追加
- App Icon / Asset Catalog追加
- Onboarding追加
- Home / Search / Calendar / Settings / BulkyWasteの情報階層再設計
- Notification permission card追加
- District setting card追加
- AppStateViewで空/エラー/読み込み/成功を統一
- split data JSON追加
- アクセシビリティラベル、ヒント、Dynamic Type対応の強化

## 参考URL

- https://www.city.kadoma.osaka.jp/kurashi/gomi/9/35805.html
- https://www.city.kadoma.osaka.jp/kurashi/gomi/9/6/4394.html
- https://developer.apple.com/design/human-interface-guidelines/tab-bars
- https://developer.apple.com/design/human-interface-guidelines/search-fields
- https://developer.apple.com/design/human-interface-guidelines/dark-mode
- https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria
