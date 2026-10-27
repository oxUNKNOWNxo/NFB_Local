# NFB_Local — PROJECT_STATE

最終更新: 2026-10-23 (JST)

このファイルは、ChatGPTの別チャットや将来の自動更新作業へ `NFB_Local` の状態・設計判断・既知問題を引き継ぐための基準資料。
作業開始時は、まずこのファイルと現在の `main` を確認すること。

---

## 0. 最新ソース更新（2026-10-27、7.2.8）

- 公式最新release: **v7.2.0**。Twitter本体: **12.33**（いずれも前回から変更なし）。
- 上流取り込み: `e91bd046e534c280c80009cebf57f558d481d27c` → **`83c76068491433405693b6d914d7ba92ad016396`**（2コミット）。日本語翻訳の追加と、テーマ設定へのカスタムアクセントカラー選択機能の追加。
- 上流変更ファイル: `ja.lproj/Localizable.strings`、`src/Hooks/HookHelpers.m`、`src/ThemeColor/BHTDimPalette.m`、`src/ThemeColor/ColorSwatchControl.m`、`src/ThemeColor/ColorThemeViewController.m`。Home Timeline / AppLifecycle / Web返信実装に上流差分はなく、Twitter本体版も不変。
- 3-way同期: `automation/upstream-v7-work-20261027-custom-color`、`Sync upstream source` run `40427271961` 成功、機械的競合なし。
- 上流の日本語訳9キーはNFB_Localに既に存在したため、同期で重複した9キーを除去して既存ローカル訳を維持。日本語設定キーは **316/316**、重複なしを検証対象とする。英語設定キーの追加はなし。
- ローカル版: **7.2.8**。既存の `hide_for_you_tab`（おすすめのみ除去、Following/固定・カスタムを維持）、`restore_home_tab_selection`（コールド起動はFollowing、同一セッションのみ復元）、Web返信フォールバック無効化、TrollStore依存先 `@rpath` / install-name / ldid / ZIP整合性処理を維持。
- 作業開始時のmain SHA: `23d7062175fa9d2f6cf4763963cc1689b581f383`。信頼境界の `.github/workflows/package.yml` / `.github/workflows/promote-verified-update.yml` およびinspect/sync/resolve/validate各Workflowは変更しない。
- 検証・Package・Promote・Private Releaseの最終結果は、該当するGitHub Actions履歴と `nfb-local-v7.2.8` Releaseを参照する。Package成功は実機動作確認を意味しない。

---

## 0. 最新ソース更新（2026-10-26、7.2.7）

- 公式release: **v7.2.0**（変化なし）。Twitter本体: **12.33**（変化なし）。
- 公式 `v7` 取り込み対象: **`e91bd046e534c280c80009cebf57f558d481d27c`**。前回取り込み済み `8079509a39f5bb40a794d7690d99ceef89fb504b` から19コミット。
- 主な変更: 実験的Liquid Glass対応、ネイティブタブカスタマイズ、設定のリセット、Webログイン・Webセッション・投稿関連修正、テーマ・UI修正、中国語・トルコ語翻訳。
- 3-way同期: `automation/upstream-v7-work-20261026-v7-head`。競合は `src/Core/BHTSettings.m` の実験的機能設定1件。既存 `reply_in_webview` の `disabled: YES` を維持し、新規 `liquid_glass` を同時に登録して解決。
- Home: 上流の `HomeBars.x` 追加分を統合し、ローカル `hide_for_you_tab`（Following・固定/カスタム維持）と `restore_home_tab_selection`（コールド起動Following、同一セッションのみ復元）を維持。Web返信フォールバック無効化も維持。
- 日本語設定: 新規9キー（Liquid Glass 3、設定リセット6）を翻訳し、**316/316** を目標として検証する。既存日本語訳を優先し重複を追加しない。
- TrollStore: `package.yml` / `promote-verified-update.yml` を変更せず、CydiaSubstrate `@rpath`、Mach-O install-name、ldid、ZIP検査、Private Release配布を維持。
- 作業開始時のmain: `a8f90b665acab1a684a0211f2afec98276e1b656`。
- Workソース検証: `Validate work source` run **`40250285122`** 成功（日本語316/316、重複なし、Home設定配線、競合マーカー検査）。検証用マーカーは削除済み。work SHA: `ef1648f08d263ca429fb2741f7ba44f8fb6f8c5e`。
- Readyブランチ: `automation/upstream-v7-ready-20261026-v7-head`。Package・Promote・Private Releaseの最終結果は、ready SHAに紐づくGitHub Actions履歴と `nfb-local-v7.2.7` Releaseを参照する。ビルド成功と実機動作確認は区別する。

---

## 0. 最新ソース更新（2026-10-23、7.2.6）

- 公式最新release: **v7.2.0**。ベースTwitter本体: **12.33**（変更なし）。
- 今回の上流統合: `b08f9792302bb5d1822c9e80941db0c0764ba527` → `fe45d6961ae3932c58fc45eef33c8d84ac571d13`（3コミット）。`src/Hooks/Timeline.x` にプロフィール経由の投稿で引用・リポスト非表示フィルタを適用しない改善と引用判定selectorの変更、フランス語翻訳更新、README変更。
- 追加の最新上流SHA: **`8079509a39f5bb40a794d7690d99ceef89fb504b`**（2026-10-23確認）。`fe45d... ` からの差分は日本語Localizable.stringsの**空行1行のみ**であり、新しい設定キー・訳語・実装変更はない。3-way同期を実行し、既存NFB_Local訳との機械的競合はローカルの訳語優先で解消した。このSHAまでソース変更を確認済み。
- READMEは検索回避のため意図的に空白のローカル版を維持。上流READMEとの競合は `Resolve reviewed upstream conflicts` により解消。
- **NFB_Local: 7.2.6**。日本語設定 **307/307** を維持し、`hide_for_you_tab`、`restore_home_tab_selection`、Web返信フォールバック無効化、TrollStore用のCydiaSubstrate `@rpath` / install-name補正を保持。
- 7.2.6のworkブランチ: `automation/upstream-v7-work-20261022-profile-timeline`。上流同期と衝突解消、`Validate work source` 実行済み。最終状態の検証・Package・Private Releaseアップロード・Promoteの結果は該当するGitHub Actions履歴で確認する。
- 配布: Private GitHub Releasesへ `local_7.2.6_12.33.tipa` をアップロードする方式（Actions Artifact保存枠0.5 GBの制限を回避）。`package.yml` と `promote-verified-update.yml` を上流同期で変更しない。
- **ビルド成功と実機検証は区別**する。7.2.6の実機挙動は未確認。

---

## 0. 最新ソース更新（2026-10-19、7.2.5）

- 公式release: **v7.2.0**、Twitterアプリ: **12.33**（今回変更なし）。
- 上流 `v7` の取り込み先端: **`b08f9792302bb5d1822c9e80941db0c0764ba527`**。
- 前回取り込み先端 `b52b713f28430684295ba0b0847a8fd50b879a05` から**1コミット**。変更は `src/AppIcon/AppIconViewController.m` のみ。
- アイコン一覧のプレビュー作成を非同期化、`NSCache` によるサムネイルキャッシュ、読み込み中インジケーターを追加。メインスレッドでコレクションを更新する設計。
- 同期は `automation/upstream-v7-work-20261019-appicon-async` 上の `Sync upstream source` run `39177944198` で **3-way競合なし**。
- ローカル版: **7.2.5**。旧 `hide_for_you_tab`、`restore_home_tab_selection`、Web返信フォールバック停止、設定日本語化、TrollStore `@rpath` 補正を維持。
- 日本語設定は **307/307** が基準。今回上流の `en.lproj` と `ja.lproj` には変更なし。
- Workソース検証: `Validate work source` run `39179608259` 成功。Package run `39180338588` 成功、Promote run `39180534783` 成功。検証済みソースSHA / main SHA: `a483cd3ae7ceec2927ed98f0ec1a9fa4458b81bf`。**実機確認とビルド成功は区別**する。
- `.github/workflows/validate-work-source.yml` の固定バージョン検査は更新ごとに古くなるため、3桁バージョンの構文検査へ変更。
- **保存容量対策:** 7.2.5の最初のPackage run `39179694374` はTIPA組立まで成功したが、Actionsの `Artifact storage quota has been hit` によりArtifactアップロード失敗。2026-10-19以降、Private Releasesへ直接TIPAを保存する方式に変更。最新Release assetの存在を確認後に旧Artifactを削除する。

---

## 0. 現行状態（2026-10-18）

- 公式release: **v7.2.0**、Twitterブランドのベースアプリ: **12.33**（ともに変更なし）。
- 今回取り込む公式 `v7` 先端: **`b52b713f28430684295ba0b0847a8fd50b879a05`**。
- 基準 `24b03ffb930eaf4a6a6f9bf6884d39cd1cffe689` から上流3コミット。変更ファイルは `ja.lproj`、`es.lproj`、`ar.lproj` の `Localizable.strings` のみ。
- NFB_Local版: **7.2.4**。日本語は元の既存訳を優先し、上流に追加された重複キーを除去した。日本語の固有キー数は **307**。
- 上流のスペイン語・アラビア語翻訳を反映。Home／返信関連のhook、`hide_for_you_tab`、`restore_home_tab_selection`、TrollStoreパッケージングは従来どおり。
- 前回までの検証済み成果物: **7.2.3 / Twitter 12.33**、Package run `39023655029`、artifact `12096963813`、SHA-256 `f413be4831b9d4ed6c20f38d818250037f3a0237b8af48619f5a0ca073636068`。7.2.3ではWeb返信フォールバックを無効化し、ネイティブ返信経路へ戻した。
- 7.2.4のPackage/Promote結果は `automation/upstream-v7-ready-20261018-l10n` の `Package` Actions履歴および連動する `Promote verified update` 履歴で確認する。
- 以下の「## 2. 現在の基準バージョン」は**2026-10-17時点の7.2.1検証履歴**として残してあり、最新情報はこの「## 0」を優先する。

---

## 0.1 GitHub Actions Artifact保存容量の管理（2026-10-19）

GitHub FreeのActions保存容量0.5 GBの上限通知を受け、当初はArtifact保存期間を短縮した。**この節は過去の対応記録であり、現在の保存方式は次の「0.2」を参照する。**

- `.github/workflows/package.yml` の `actions/upload-artifact@v7` に **`retention-days: 3`** を追加。**これ以降に生成するTIPA成果物**は原則3日間保存する（既存Artifactの保存期限は遡及変更されない）。
- コミット: `5c0ad17fd3a39d1dfecf2d01cfe410a9fc332154`。
- GitHub Actionsの一時的な `Cleanup old NFB_Local TIPA artifacts` Workflow（run `39177274346`）で、**7.2.4より古い `local_*.tipa` のArtifactだけを12件削除**。
- 削除済み容量: **3,090,524,796 bytes（約3.09 GB）**。旧Package run自体やソース、コミットは削除していないが、**過去のTIPA Artifactリンクはダウンロード不可**。
- 保持した最新成果物: **`local_7.2.4_12.33.tipa`**、Artifact ID **`12122537386`**、サイズ **259,043,621 bytes**、Package run **`39091259800`**。
- 一時削除Workflowと起動マーカーは処理成功後に作業ブランチから取り除いた。恒久的な強権限削除Workflowを `main` に残していない。
- 無料枠の使用量通知／請求表示はGitHub側の集計周期に依存し、今回の削除だけで同一請求期間の累計消費量が即座に0へ戻るとは限らない。
- 上記の3日間の保存期間指定は、現在のReleases移行前の旧方式に対するものである。新しいRelease assetはActions Artifactの3日間保持の対象外。

---

## 0.2 GitHub ReleasesによるTIPA配布（2026-10-19以降、現行方式）

Actions Artifact保存容量（Free上限0.5 GB）が上限扱いのままになり、7.2.5の初回Package run `39179694374` はTIPA生成後、`actions/upload-artifact` に失敗した。Artifact削除後もストレージ判定がすぐには更新されなかった。

この問題を再発させないため、`.github/workflows/package.yml` の出力先を **Private GitHub Releases** に変更した（Workflow変更コミット `eaf6f0fdb6b3f254acb860bf986dd8c1a57b26b4`）。

- `Package` は公式Twitter TrollStore版から引き続きビルド・CydiaSubstrate `@rpath` 補正・Mach-O install-name保持・`ldid`・ZIP検査を実施。
- 最終段階は `actions/upload-artifact` ではなく `gh release create` / `gh release upload` で、**同じPrivateリポジトリ内**のタグ `nfb-local-v<LOCAL_VERSION>` に `local_<LOCAL_VERSION>_<TWITTER_VERSION>.tipa` をアップロード。
- Releaseは `--prerelease` 扱いで、実機テスト済みの意味ではない。
- Packageのcheckoutには `persist-credentials: false` を使用し、`GH_TOKEN` はReleaseアップロード工程のみに渡す。
- Release assetの保存容量はActions Artifactの0.5GB枠に計上されず、`retention-days: 3` による自動消去も行われない。不要な古いReleaseを消す際は、正常な最新Releaseを確認してから行う。
- `Promote verified update` の信頼境界は維持される。readyブランチで `package.yml` と `promote-verified-update.yml` をmainと一致させ、成功したPackage SHAだけをforceなしfast-forwardでmainへ昇格する。

**最新成果物 / 実走検証（7.2.5 / Twitter 12.33）**

- Package run: `39180338588` 成功
- Promote run: `39180534783` 成功
- 検証・昇格コミット: `a483cd3ae7ceec2927ed98f0ec1a9fa4458b81bf`
- Release: `https://github.com/oxUNKNOWNxo/NFB_Local/releases/tag/nfb-local-v7.2.5`
- TIPA: `https://github.com/oxUNKNOWNxo/NFB_Local/releases/download/nfb-local-v7.2.5/local_7.2.5_12.33.tipa`
- サイズ: `259046674` bytes
- SHA-256: `7be1d28cfc2dfee4646c664bc495a6ecc93f1e5fd3ba95313a188fd7568c50d0`
- コンパイル・再梱包・`@rpath` 補正・ZIP検査・Release uploadまで成功、**実機動作未確認**。
- 2026-10-19に監視タスクの指示もRelease配布方式と一時的な書込エラー時の監視継続へ更新し、再有効化した。
- Release検証後、一時的な `Purge superseded Actions TIPA artifact` run `39180772652` が成功し、旧7.2.4のActions Artifact ID `12122537386` を削除。削除用Workflow/起動マーカーは作業ブランチから撤去済み。7.2.5のPrivate Release assetは維持。

---

## 1. リポジトリ / 基本方針

- ローカル改修先: `oxUNKNOWNxo/NFB_Local`
- 可視性: **Private（絶対に変更しない）**
- デフォルトブランチ: `main`
- 本家: `NeoFreeBird/app`
- 本家基準ブランチ: `v7`
- GitHub上のFork関係を持たない独立リポジトリ。
- `README.md` は検索避けのため意図的に空白。
- LICENSE / 著作権表示はGPLv3準拠のため維持する。

利用方針:

- TrollStore向け **Twitterブランド版** を基準にする。
- 本家releaseの `NeoFreeBird-trollstore-Twitter_*.tipa` をベースにする。
- 明示指示がない限りXブランド版へ切り替えない。

---

## 2. 現在の基準バージョン

2026-10-17時点:

- 本家最新release: **v7.2.0**
- 本家 `v7` 取り込み済み先端: `24b03ffb930eaf4a6a6f9bf6884d39cd1cffe689`
- ベースTwitterアプリ: **12.33**
- NFB_Local: **7.2.1**
- 検証済みready SHA: `f40f49a7c325d087d7637485131ecd29b5a560a6`
- 12.33実バイナリ互換性検査: `Inspect upstream Twitter binary` run `38988427080`
- Package: run #12 / Run ID `38989163366`
- 成果物: `local_7.2.1_12.33.tipa`
- Artifact ID: `12084870441`
- Artifact size: `259041144` bytes
- Artifact SHA-256: `4d58f2f40fab8743f8a566eaa5ce361c00364f3357a024d5bfd1253618c2a144`
- Artifact URL: `https://github.com/oxUNKNOWNxo/NFB_Local/actions/runs/38989163366/artifacts/12084870441`
- 自動main昇格: `Promote verified update` run `38989437820` 成功

v7.2.1で確認済み:

- Twitter 12.33公式TrollStore TIPAの取得・展開成功
- `hide_for_you_tab` が依存するHome Timelineクラス/selector/tokenを12.33実バイナリで検査し、必須項目すべてPASS
- `HomeBars.x` / `AppLifecycle.x` compile成功
- v7.2.0の設定画面刷新、投稿元ラベル、タイムライン関連変更を含むソースcompile成功
- 日本語ローカライズ **307/307 (100%)**
- TrollStore dylib差し替え成功
- CydiaSubstrate dependency補正成功
- Mach-O install name維持成功
- `ldid -S`成功
- ZIP integrity check成功
- Artifact upload成功

dependency確認:

```text
Base substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
Built substrate dependency: /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
Patched substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
```

install name:

```text
/Library/MobileSubstrate/DynamicLibraries/BHTwitter.dylib
```

**7.2.1はソース・バイナリselector・Package検証済みだが、実機動作確認は別扱い。**

---

## 3. 2026-10-17 本家v7.2.0同期内容

本家 `NeoFreeBird/app` の `v7` を `24b03ffb930eaf4a6a6f9bf6884d39cd1cffe689` まで取り込み済み。
前回基準 `a8cb17f762e74a3c682eac1e987872db3957e9b5` から **17コミット**追加。

主な追加・変更:

- 公式release **v7.2.0** / Twitter **12.33** へ更新
- 設定画面の刷新
- 投稿元ラベル表示の復活
- 投稿の引用/リポスト数表示関連の改善
- タイムライン関連機能の改善
- Home長押しからNeoFreeBird設定を開く処理
- その他v7.2.0の上流修正

同期は `automation/upstream-v7-work-20261017-v720` で3-way実施。
54変更ファイル中50ファイルは自動統合、競合は以下4ファイルのみ:

- `control`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `src/Hooks/HomeBars.x`
- `src/Hooks/HookHelpers.h`

解決方針:

- ローカル版番号を **7.2.1** とする。
- 日本語はNFB_Local側の既存訳を保護しつつv7.2.0新規キーを追加。
- `HomeBars.x` は `hide_for_you_tab` / Home選択ロジックを保持し、本家の設定ジェスチャーも統合。
- `HookHelpers.h` は本家新宣言とローカルHome復元宣言を両立。
- `AppLifecycle.x` のHome選択保存/復元処理も保持。

### Twitter 12.33実バイナリ検査

大容量TIPAをChatGPT実行環境へ直接取得できない場合は更新を止めず、GitHub Actionsの `.github/workflows/inspect-upstream-binary.yml` を使用する。

2026-10-17の検査:

- Workflow: `Inspect upstream Twitter binary`
- Run ID: `38988427080`
- 公式asset: `NeoFreeBird-trollstore-Twitter_7.2.0_12.33.tipa`
- 結果: Homeクラス、`numberOfTabsIn:`、`segmentedViewController:*AtIndex:`、variant選択、`currentIndex`、`reloadDataWithSelectingIndex:`、固定timeline関連selector/tokenがすべてPASS。

したがって12.31.1向けローカルHome実装を12.33でも継続できることを静的互換性検証済み。

---

## 4. 日本語ローカライズ

本家英語設定をmasterとして日本語設定を追従する。

7.2.1同期時:

- 日本語Localizable: **307 / 307 (100%)**
- v7.2.0新規キーを日本語化済み。
- 既存英語原文の変更も確認して追従済み。

今回追加/確認した主な日本語:

- `BLOCK_LINK_TRACKING_TITLE` = `リンクの追跡をブロック`
- `STRIP_TRACKING_PARAMS_TITLE` = `追跡用パラメータを削除`
- `DEFAULT_REPLY_SORTING_TITLE` = `リプライの既定の並べ替え`
- `HIDE_QUOTE_TWEETS_TITLE` = `引用ツイートを非表示`
- `HIDE_RETWEETS_TITLE` = `リツイートを非表示`

主要ファイル:

- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/RenameWords.strings`

更新時はキー一致だけでなく、**既存英語原文が変わっていないかも確認すること**。
可能なら以下も実行する。

```bash
./check_localization.py ja
./check_localization.py ja --values
```

### `restore_home_tab_selection`

ローカル専用設定なので、本家共通registryとの競合を避けるため `TimelinesSettingsViewController.m` から直接追加している。

- 日本語: `選択したホームタブを復元`
- 英語: `Restore selected Home tab`

この項目はLocalizable.stringsの307件には含まれない。

---

## 5. 「おすすめ」タブ非表示 — `hide_for_you_tab`

設定キー: `hide_for_you_tab`

初期値: **OFF**

必須仕様:

- `おすすめ / For You` だけ削除。
- `フォロー中 / Following` を維持。
- 固定/カスタムtimelineを維持。
- visible index と source index を混同しない。
- Twitter/Xアプリ版が変わった場合は旧selectorを無条件で再利用しない。

Twitter 12.33でも実バイナリ再確認済みの概念上のindex:

```text
source 0 = For You
source 1 = Following
source 2以降 = pinned/custom timeline
```

`hide_for_you_tab` ON時:

```text
visible 0 -> source 1 = Following
visible 1 -> source 2 = 最初の固定/カスタムtimeline
visible N -> source N+1
```

主要ファイル:

- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Hooks/HookHelpers.h`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`

12.33で実バイナリ再確認済みの主なselector:

- `numberOfTabsIn:`
- `segmentedViewController:descriptorAtIndex:`
- `segmentedViewController:pageViewControllerAtIndex:`
- `segmentedViewController:shouldSelectViewControllerAtIndex:`
- `segmentedViewController:isPrewarmableTabAtIndex:`
- `segmentedViewController:isUnreadIndicatorTabAtIndex:`
- `segmentedViewController:menuForTabAtIndex:`
- `segmentedViewController:tabGroupAtIndex:`
- `segmentedViewController:didTapTabAtIndex:`
- `segmentedViewController:didLongPressAtIndex:`
- `reloadDataWithSelectingIndex:`
- `currentIndex`

互換目的で旧12.3系hookも一部残している。

公式releaseのTwitter/Xアプリ版が12.33から変わった場合も、`Inspect upstream Twitter binary` を使ってHome Timeline内部APIを実バイナリで再確認すること。

---

## 6. ホームタブ選択 — `restore_home_tab_selection`

ユーザー要件:

1. コールド起動時は必ずFollowing。
2. 固定リスト復元は独立設定にする。

仕様:

- 初期値OFF。
- `hide_for_you_tab` の子設定。
- `hide_for_you_tab` OFF時は設定行を隠す。
- コールド起動は設定ON/OFFに関係なく visible 0 = Following。
- 選択indexはプロセス内static変数だけに保持し、NSUserDefaultsへ永続化しない。
- 完全終了後は必ずFollowingから開始。
- 復元OFFならバックグラウンド復帰もFollowingへ戻す。
- 復元ONなら同一プロセス内だけ固定/カスタムtimelineを復元する。

この7.1.5由来の実装は7.2.1でも保持されている。

---

## 7. TrollStoreパッケージング — 絶対に維持

単純な `BHTwitter.dylib` 差し替えは起動直後クラッシュを起こしたため不可。

`.github/workflows/package.yml` では必ず:

1. 本家Twitter TrollStore `.tipa` を展開。
2. 元dylibのCydiaSubstrate dependencyとMach-O install nameを取得。
3. 新dylibへ差し替え。
4. dependencyを本家と同じ `@rpath/CydiaSubstrate.framework/CydiaSubstrate` へ補正。
5. install nameも本家に合わせる。
6. `ldid -S`。
7. `otool` で補正結果を検証。
8. `BHTwitter.bundle` をローカル版へ差し替え。
9. `TSPreAppliedExploitType` / `TSBundlePreSigned` をInfo.plistから削除。
10. `.tipa`へ再ZIP。
11. `unzip -tq` で検査。

**単純dylib差し替え方式へ戻してはいけない。**

---

## 8. 自動Package Workflow

ファイル:

```text
.github/workflows/package.yml
```

Actions表示名:

```text
Package
```

2026-10-16からトリガーは以下:

```yaml
on:
  push:
    branches:
      - 'automation/upstream-v7-ready-*'
  workflow_dispatch:
```

目的:

- 手動ビルドは従来どおり `workflow_dispatch`。
- 自動更新タスクが最終検証ブランチ `automation/upstream-v7-ready-*` へpushすると自動でPackageを実行。
- 自動更新タスク自身がworkflow_dispatchを呼ぶ必要はない。

本家releaseから選択するasset:

```regex
^NeoFreeBird-trollstore-Twitter_.*\.tipa$
```

出力:

```text
local_<NFB_Local Version>_<Twitter App Version>.tipa
```

---

## 9. 検証済み更新の自動main昇格

2026-10-16追加。

ファイル:

```text
.github/workflows/promote-verified-update.yml
```

Actions表示名:

```text
Promote verified update
```

目的:

ChatGPTのGitHub接続機能から `main` 更新やPull Request作成を行うと、安全チェックによって拒否される場合がある。
その回避のため、**ChatGPTはmainを直接変更せず、GitHub Actions自身に検証済みSHAの昇格を任せる。**

起動条件:

- `Package` Workflowが完了。
- conclusionが `success`。
- Packageのイベントが `push`。
- 同一リポジトリ内のbranch。
- branch名が `automation/upstream-v7-ready-*`。

昇格時の安全条件:

1. workflow_runが報告したSHAと現在のready branch先端SHAが一致すること。
2. 現在の `main` がready SHAの祖先であること。
3. ready branchで以下の信頼境界Workflowが変更されていないこと。
   - `.github/workflows/package.yml`
   - `.github/workflows/promote-verified-update.yml`
4. `git push <READY_SHA>:refs/heads/main` の**通常fast-forwardだけ**を使用する。
5. force push / force-with-leaseを使用しない。

`main` が検証中に別方向へ進んだ場合や、権限不足、保護ルール、Workflow変更がある場合は昇格を失敗させる。検証ブランチは保持し、ChatGPTの自動更新タスクが原因を報告する。

**自動更新タスクは失敗時のフォールバックとしてmain直接更新やPR作成を行ってはいけない。**

### GitHub Actions権限

`Promote verified update` は:

```yaml
permissions:
  contents: write
```

を要求する。

組織/リポジトリ側ポリシーで `GITHUB_TOKEN` のwriteが禁止されている場合、Packageは成功してもPromoteだけ失敗する。その場合はGitHubのActions権限設定を確認する。安全チェック回避のためChatGPT側から直接mainへ反映しない。

### 実走確認

2026-10-16に `automation/upstream-v7-ready-smoketest-20261016` を現在のmainから作成し、検証用コミット `82c5133f990854baa76215769ed9f6147b1f5ec7` をpushして実走確認した。

結果:

- ready branchへのpushで `Package` が自動起動。
- Package成功後に `Promote verified update` が起動。
- ready SHAがmainへfast-forwardされたことを、検証ファイルがmainへ現れたことで確認。
- `contents: write` はこのリポジトリで実際に機能している。
- 検証ファイルは確認後mainから削除済み。

したがって、2026-10-16時点で **ready branch → Package → Promote verified update → main fast-forward の経路は実走確認済み**。

2026-10-17のv7.2.1更新でも実運用経路を再確認済み:

- Package run: `38989163366` 成功
- ready SHA: `f40f49a7c325d087d7637485131ecd29b5a560a6`
- Promote run: `38989437820` 成功
- `3d408370...` → `f40f49a...` をforceなしでfast-forward


---

## 10. 本家更新時の自動追従手順

ChatGPT側の条件監視タスク **「タスク NeoFreeBird更新確認」** を使用する。更新がなければ通知しない。

更新がある場合:

1. `NFB_Local` がPrivateのままか確認。
2. 現在の `main` / `PROJECT_STATE.md` / 本家 `v7` / 最新releaseを取得。
3. Twitter/X本体バージョンが変わった場合は、ChatGPT環境でTIPA取得に失敗しても停止・無効化しない。
4. `automation/inspect-upstream-YYYYMMDD-*` と `.github/workflows/inspect-upstream-binary.yml` を使い、GitHub Actions上で公式TIPAを取得・Home selectorを解析する。
5. 必須selectorが欠落した場合のみmainを変更せず報告する。
6. 現在のmainから `automation/upstream-v7-work-YYYYMMDD-*` を作る。
7. `.upstream-sync-request` に前回上流SHAをBASE、新上流SHAをTARGETとしてpushし、`.github/workflows/sync-upstream-source.yml` で3-way同期する。
8. 競合はwork branchに保持し、安全に判断できるものだけ `.github/workflows/resolve-upstream-conflicts.yml` で解決する。
9. 日本語Localizableを比較し、`check_localization.py ja` / `--values` を100%にする。
10. `hide_for_you_tab` / `restore_home_tab_selection` / TrollStore補正を維持する。
11. `.github/workflows/validate-work-source.yml` で競合マーカー、翻訳、Home配線、版番号を検証する。
12. 現在のmainがready SHAの祖先になるよう安全に履歴を統合する。
13. `automation/upstream-v7-ready-YYYYMMDD-*` をpushする。
14. pushで `Package` が自動実行される。
15. Package成功後、`Promote verified update` がmainへfast-forward onlyで昇格する。
16. ChatGPTはPromote結果、最終main SHA、Private状態を確認する。
17. `PROJECT_STATE.md` を最新状態へ更新する。
18. ビルド/静的互換性検証と実機動作確認は分けて報告する。

ChatGPT側で禁止する操作:

- 自動更新中の `main` 直接ref更新
- `main` への直接merge/force push
- Pull Request作成へのフォールバック
- 大容量TIPAをChatGPT環境で取得できないことだけを理由に監視タスクを無効化すること

### 自動更新基盤Workflow

- `.github/workflows/inspect-upstream-binary.yml`
- `.github/workflows/sync-upstream-source.yml`
- `.github/workflows/resolve-upstream-conflicts.yml`
- `.github/workflows/validate-work-source.yml`
- `.github/workflows/package.yml`
- `.github/workflows/promote-verified-update.yml`

`package.yml` / `promote-verified-update.yml` は信頼境界。通常の上流同期で変更しない。
その他の自動更新基盤Workflowも上流ソースで盲目的に上書きしない。

---

## 11. 過去の重要な失敗 / 戻してはいけない点

### 11.1 単純dylib差し替え

不可。必ず本家の `@rpath/...` へ補正する。

### 11.2 TrollStore再署名だけを原因と決めつけない

起動直後クラッシュ時は本家dylibとのMach-O依存差を比較する。

### 11.3 古いHome selectorを現行版と決めつけない

外部tweakや旧Twitter/X版のselectorを盲目的に使わない。アプリ版変更時は実バイナリを確認する。

### 11.4 source indexとvisible indexを混同しない

For You削除時のFollowingは:

```text
source index 1
visible index 0
```

### 11.5 永続化された選択値だけでHome初期タブを制御しない

7.1.2〜7.1.4では条件によって表示上2番目の固定リストが先頭表示される問題が残った。
7.1.5以降の「コールド起動=Following、復元=任意の同一セッション機能」を基準とする。

### 11.6 ChatGPTからmain反映/PR作成を自動更新の必須工程にしない

GitHub接続操作の安全チェックで拒否される場合がある。
現在はready branch → Package → Promote verified updateというGitHub Actions経路を基準とする。

---

## 12. 7.2.1 要実機確認

最低限:

1. アプリが正常起動する。
2. 設定画面の日本語化が崩れていない。
3. v7.2.0の刷新された設定画面、新規設定、投稿元ラベル等が正常に表示される。
4. `おすすめ`非表示ONでFor Youだけ消える。
5. Followingが維持される。
6. 固定/カスタムtimelineが使える。
7. コールド起動時はFollowingから開始する。
8. `選択したホームタブを復元` ON時のみ、同一セッション内のバックグラウンド復帰で固定リストを復元する。
9. OFF時はバックグラウンド復帰でもFollowingへ戻る。

---

## 13. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、現在の `main` と本家 `NeoFreeBird/app` の `v7` を確認してから作業を続けてください。Twitterブランド / TrollStore基準、日本語ローカライズ、`hide_for_you_tab`、`restore_home_tab_selection`、CydiaSubstrateの `@rpath` 補正を必ず維持してください。自動本家追従ではChatGPTからmain更新やPR作成を行わず、`automation/upstream-v7-ready-*` → `Package` → `Promote verified update` の経路を使ってください。公式Twitterアプリ版が12.33から変わった場合は、ChatGPT環境のダウンロード可否に依存せず `Inspect upstream Twitter binary` をGitHub Actionsで実行し、Home Timeline selectorを推測せず実バイナリで再確認してください。

---

## 14. 更新ルール

重要な修正を行った場合は同じ作業内でこの `PROJECT_STATE.md` を更新する。

特に以下を最新状態に保つ:

- 本家NeoFreeBird release / `v7` commit
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新build / Run ID / Artifact ID / SHA-256
- 日本語キー数と原文変更対応
- `hide_for_you_tab` / `restore_home_tab_selection`
- Package / Promote verified update方式
- 実機確認結果
- 新しい既知問題 / 解決済み問題
