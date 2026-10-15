# NFB_Local — PROJECT_STATE

最終更新: 2026-10-15 (JST)

このファイルは、ChatGPTの別チャットや将来の作業へ `NFB_Local` の状態・設計判断・既知問題を引き継ぐための基準資料。
作業開始時は、まずこのファイルと現在の `main` を確認すること。

---

## 1. リポジトリ / 基本方針

- ローカル改修先: `oxUNKNOWNxo/NFB_Local`
- 可視性: **Private（絶対に変更しない）**
- デフォルトブランチ: `main`
- 本家: `NeoFreeBird/app`
- 本家基準ブランチ: `v7`
- GitHub上のFork関係を持たない独立リポジトリ。
- `README.md` は検索避けのため意図的に空白。
- Actionsは中立名の `Package` を主用途とする。
- LICENSE / 著作権表示はGPLv3準拠のため維持する。

### 利用環境 / 必須方針

- 利用方法: **TrollStore**
- ブランド: **Twitter版を基準**
- Xブランド版ではなく、本家release内の `NeoFreeBird-trollstore-Twitter_*.tipa` を使用する。
- 今後も明示指示がない限りX版へ切り替えない。

---

## 2. 現在の基準バージョン

2026-10-15時点:

- 本家最新release: **v7.1.1**
- 本家 `v7` 取り込み済み先端: **`a8cb17f762e74a3c682eac1e987872db3957e9b5`**
- ベースTwitterアプリ: **12.31.1**
- NFB_Local: **7.1.6**
- 7.1.6ソース検証ブランチ: `automation/upstream-v7-ready-20261015`
- 7.1.6同期コミット: `1272fdfa21aa119d359910e305903ec35e376a3e`
- 7.1.6ビルド: GitHub Actions `Package` run #7
- Run ID: `38659559714`
- 成果物: `local_7.1.6_12.31.1.tipa`
- Artifact ID: `11938158386`
- Artifact size: `257053961` bytes
- Artifact SHA-256:
  `cf532f5ef79b716759ea4ea8d6c4070cde8685ca8ca1a1d2275f2a336053a302`
- Artifact URL:
  `https://github.com/oxUNKNOWNxo/NFB_Local/actions/runs/38659559714/artifacts/11938158386`

### run #7 検証状態

run #7は `automation/upstream-v7-20261015` の `647b543c64967fbc534e45e78644da592cd32a91` で実行された。
このビルド用コミットには検証目的のpush triggerだけが一時的に存在した。
最終検証ブランチ `automation/upstream-v7-ready-20261015` ではpush triggerを除去して `workflow_dispatch` のみに戻している。

ビルド用コミットと最終検証ブランチについて、アプリ動作に関係する主要blobを比較済み。少なくとも以下は同一:

- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Hooks/Ads.x`
- `src/Hooks/FeatureSwitches.x`
- `src/Core/BHTSettings.m`
- 英語 `Localizable.strings`
- 日本語 `Localizable.strings`

したがって、run #7は最終検証ブランチと同一の実装内容をビルドしたものとして扱える。最終ブランチ側の実質的な差は、検証用push triggerを削除した通常運用用 `Package` workflow。

run #7で確認済み:

- `HomeBars.x` compile成功
- `AppLifecycle.x` compile成功
- 新規 `LinkTracking.x` compile成功
- 新規 `ReplySorting.x` compile成功
- `Timeline.x` compile成功
- 設定画面関連 compile成功
- TrollStore Twitter base取得成功
- dylib差し替え成功
- CydiaSubstrate dependency補正成功
- Mach-O install name維持成功
- `ldid -S`成功
- ZIP integrity check成功
- Artifact upload成功

確認されたdependency:

```text
Base substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
Built substrate dependency: /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
Patched substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
```

install name:

```text
/Library/MobileSubstrate/DynamicLibraries/BHTwitter.dylib
```

### 実機確認

**7.1.6はビルド成功のみ。実機での起動・各機能の動作確認は未実施。**
ビルド成功と実機動作確認を混同しないこと。

---

## 3. 2026-10-15 本家v7同期内容

本家 `NeoFreeBird/app` の `v7` を `a8cb17f762e74a3c682eac1e987872db3957e9b5` まで取り込み済み。
主な追加・変更:

- t.coリンク追跡のブロック
- URLの `utm_` 等追跡パラメータ削除
- リプライの既定の並べ替え設定
- リプライ並べ替えボタン非表示の説明/仕様整理
- 引用ツイート非表示
- リツイート非表示
- 広告除去処理の改善
- `RenameWords.strings` の日本語リソース追加
- 関連header / feature switch / timeline / Web投稿処理の更新

この同期で `HomeBars.x` / `AppLifecycle.x` / `TimelinesSettingsViewController.m` は上書きしていないため、ローカル独自Home処理は維持されている。

---

## 4. 日本語ローカライズ

本家英語設定をmasterとして、日本語設定を追従する。

7.1.6同期時の確認:

- 英語 / 日本語の設定キー構成: **303 / 303**
- 今回追加された新規キーの日本語訳を追加済み。
- 英語原文が変更された `REPLY_SORTING_DETAIL` も意味に合わせて更新済み。

今回追加/確認した主な日本語:

- `BLOCK_LINK_TRACKING_TITLE` = `リンクの追跡をブロック`
- `BLOCK_LINK_TRACKING_DETAIL`
- `STRIP_TRACKING_PARAMS_TITLE` = `追跡用パラメータを削除`
- `STRIP_TRACKING_PARAMS_DETAIL`
- `DEFAULT_REPLY_SORTING_TITLE` = `リプライの既定の並べ替え`
- `DEFAULT_REPLY_SORTING_DETAIL`
- `HIDE_QUOTE_TWEETS_TITLE` = `引用ツイートを非表示`
- `HIDE_QUOTE_TWEETS_DETAIL`
- `HIDE_RETWEETS_TITLE` = `リツイートを非表示`
- `HIDE_RETWEETS_DETAIL`
- `REPLY_SORTING_DETAIL` = 返信欄の並べ替えボタンを非表示にする意味へ更新

主要ファイル:

- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/RenameWords.strings`

更新時は可能なら:

```bash
./check_localization.py ja
./check_localization.py ja --values
```

を確認する。

固有名詞 (`NeoFreeBird`, `Grok`, `OK` 等) は必要がなければ翻訳しない。

### `restore_home_tab_selection` の表示文字列

ローカル専用設定 `restore_home_tab_selection` は本家共通registryとの競合を避けるため、`TimelinesSettingsViewController.m` から直接ページへ追加している。

- 日本語: `選択したホームタブを復元`
- 英語: `Restore selected Home tab`

この項目は `Localizable.strings` の303件には含まれない。

---

## 5. 「おすすめ」タブ非表示 — `hide_for_you_tab`

追加設定キー:

```text
hide_for_you_tab
```

現在のdefault:

- **OFF**

必須仕様:

- `おすすめ / For You` だけを削除する。
- `フォロー中 / Following` は維持する。
- 固定/カスタムtimelineを維持する。
- visible index と source index を混同しない。
- 新しいTwitter/Xアプリ版へ移行した場合、古いselectorを無条件に再利用しない。

### 12.31.1のindex設計

概念上:

- source 0 = For You
- source 1 = Following
- source 2以降 = pinned/custom timeline

`hide_for_you_tab` ON時:

- visible 0 -> source 1 = Following
- visible 1 -> source 2 = 最初の固定/カスタムtimeline
- visible N -> source N+1

現在の主要実装ファイル:

- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Hooks/HookHelpers.h`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`

12.31.1で実バイナリ確認済みの主なselector:

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

### 今回7.1.6で再解析しなかった理由

2026-10-15時点の本家最新releaseは依然 `v7.1.1`、Twitter baseも **12.31.1** のまま。
今回の変更はNeoFreeBirdソース側の12コミットであり、対象Twitter実行バイナリ自体は変わっていない。
そのため、既に12.31.1で確認したHome Timeline selectorを新しいX/Twitter版向けに再推測・再実装する必要はない。

次回、公式releaseのTwitter/Xバージョンが12.31.1から変わった場合は、Home Timeline内部APIを実バイナリで再確認すること。

---

## 6. ホームタブ選択 — `restore_home_tab_selection`

ユーザー要件:

1. コールド起動時は**必ずFollowing**を選択。
2. 固定リストを復元する処理は独立した設定項目にする。

設定キー:

```text
restore_home_tab_selection
```

仕様:

- 初期値OFF。
- `hide_for_you_tab` の子設定。
- `hide_for_you_tab` OFF時は設定行を隠す。
- コールド起動は設定ON/OFFに関係なく visible 0 = Following。
- 選択indexはプロセス内static変数にのみ保持し、NSUserDefaultsへ永続化しない。
- 完全終了後は必ずFollowingから開始。

復元設定OFF:

- バックグラウンド復帰でもFollowingへ戻す。

復元設定ON:

- `applicationWillResignActive:` で現在のvisible indexを保存。
- `applicationDidBecomeActive:` 後に同一プロセス内でそのindexへ復元。
- 固定/カスタムtimelineを選択していた場合だけ同じ起動セッション内で復元可能。

この7.1.5由来の実装は7.1.6同期でも保持されている。

**7.1.6での実機確認はまだ。**

---

## 7. 本家7.1.6同期で追加された設定

`BHTSettings.m` で以下を確認済み。

### タイムライン

```text
hide_retweets        default OFF
hide_quote_tweets    default OFF
```

### ポストと返信

```text
default_reply_sort   default 0
```

`showReplySortPicker:` を使用するcompactButton。

### ウェブとリンク

```text
block_link_tracking    default ON
strip_tracking_params  default ON
```

---

## 8. TrollStoreパッケージング — 絶対に維持する処理

過去に本家Twitter TrollStore `.tipa` 内の `BHTwitter.dylib` を単純差し替えしたところ、起動直後クラッシュした。

原因となったdependency差:

本家配布版:

```text
@rpath/CydiaSubstrate.framework/CydiaSubstrate
```

Theos新規build:

```text
/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
```

`.github/workflows/package.yml` では必ず以下を維持する:

1. 本家Twitter TrollStore `.tipa` を展開。
2. 元dylibからCydiaSubstrate dependencyとMach-O install nameを取得。
3. 新規dylibへ差し替え。
4. `install_name_tool` でdependencyを本家と同一に補正。
5. install nameも本家に合わせる。
6. `ldid -S` で署名。
7. `otool` で補正結果を検証。
8. `BHTwitter.bundle` をローカル版へ差し替え。
9. Info.plistから `TSPreAppliedExploitType` / `TSBundlePreSigned` を削除。
10. `.tipa`へ再ZIP。
11. `unzip -tq` で検査。

**単純dylib差し替え方式へ戻してはいけない。**

---

## 9. Package Workflow

- ファイル: `.github/workflows/package.yml`
- Actions表示名: `Package`
- 通常トリガー: **`workflow_dispatch`のみ**
- 検証目的でpush triggerを一時追加した場合、run開始後に必ずmanual-onlyへ戻す。

本家releaseから以下のみ選択:

```regex
^NeoFreeBird-trollstore-Twitter_.*\.tipa$
```

出力:

```text
local_<NFB_Local Version>_<Twitter App Version>.tipa
```

現在:

```text
local_7.1.6_12.31.1.tipa
```

---

## 10. 本家更新時の追従手順

本家 `NeoFreeBird/app` にrelease/source updateがあった場合:

1. `main` と本家 `v7` の差分を取得。
2. 本家変更をローカルへ丸ごと上書きしない。
3. ローカル独自改造を先に保護する。
4. 本家修正・新機能を取り込む。
5. 英語Localizableの追加・変更キーを日本語へ反映。
6. キー一致だけでなく、既存英語原文の変更も確認する。
7. `hide_for_you_tab` / `restore_home_tab_selection` を維持。
8. 公式Twitter/Xアプリ版が変わった場合はHome Timeline selectorを実バイナリで再解析。
9. TrollStore `@rpath`補正等を維持。
10. Compile / Assemble / Artifact生成まで確認。
11. ビルド成功と実機動作確認を分けて記録。
12. この `PROJECT_STATE.md` を更新。

特に競合確認するファイル:

- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`
- `src/Hooks/FeatureSwitches.x`
- `src/Hooks/Timeline.x`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `.github/workflows/package.yml`
- `control`

---

## 11. 自動更新監視

ChatGPT側に条件監視タスク **「NeoFreeBird追従更新」** を設定済み。

方針:

- 本家更新がなければ通知しない。
- 更新があればNFB_Localへ安全に取り込む。
- 日本語化を更新。
- `hide_for_you_tab` / `restore_home_tab_selection` を維持。
- 新Twitter版なら内部APIを確認。
- TrollStore Package/buildまで進める。
- 安全に解決できない競合は動作中の版を壊さず通知する。

---

## 12. 過去の重要な失敗 / 戻してはいけない点

### 12.1 単純dylib差し替え

不可。必ず本家の `@rpath/...` へ補正する。

### 12.2 TrollStore再署名だけを原因と決めつけない

起動直後クラッシュ時はまず本家dylibとのMach-O依存差を比較する。

### 12.3 古いHome selectorを現行版と決めつけない

外部tweakや旧X/Twitter版のselectorを盲目的に使用しない。
アプリ版が変わったら実バイナリを確認する。

### 12.4 source indexとvisible indexを混同しない

For Youを削除するとFollowingは:

- source index 1
- visible index 0

になる。

### 12.5 永続化された選択値だけでHome初期タブを制御しない

7.1.2〜7.1.4で、保存キー削除や一度だけの0番補正では条件によって2番目の固定リストが先頭表示される問題が残った。
現在は7.1.5以降の「コールド起動=Following、復元=任意の同一セッション機能」の設計を基準とする。

---

## 13. 現在の要実機確認

7.1.6をTrollStoreで実機確認する際は最低限:

1. アプリが正常起動する。
2. 設定画面の日本語化が崩れていない。
3. 新規設定（リンク追跡、既定リプライ並べ替え、引用/リツイート非表示）が表示される。
4. `おすすめ`非表示ONでFor Youだけ消える。
5. Followingが維持される。
6. 固定/カスタムtimelineが使える。
7. コールド起動時はFollowingから開始する。
8. `選択したホームタブを復元` ON時のみ、同一セッション内のバックグラウンド復帰で固定リストを復元する。
9. OFF時はバックグラウンド復帰でもFollowingへ戻る。

---

## 14. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、現在の `main` と本家 `NeoFreeBird/app` の `v7` を確認してから作業を続けてください。Twitterブランド / TrollStore基準、日本語ローカライズ、`hide_for_you_tab`、`restore_home_tab_selection`、CydiaSubstrateの `@rpath` 補正を必ず維持してください。公式Twitterアプリ版が12.31.1から変わった場合は、Home Timeline selectorを推測せず実バイナリで再確認してください。

---

## 15. 更新ルール

重要な修正を行った場合は同じ作業内でこの `PROJECT_STATE.md` を更新する。

特に:

- 本家NeoFreeBird release / `v7` commit
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新build / Run ID / Artifact ID / SHA-256
- 日本語キー数と原文変更対応
- `hide_for_you_tab` / `restore_home_tab_selection` の互換実装
- Package方式
- 実機確認結果
- 新しい既知問題 / 解決済み問題

を最新状態に保つ。
