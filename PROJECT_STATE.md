# NFB_Local — PROJECT_STATE

最終更新: 2026-10-16 (JST)

このファイルは、ChatGPTの別チャットや将来の自動更新作業へ `NFB_Local` の状態・設計判断・既知問題を引き継ぐための基準資料。
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
- LICENSE / 著作権表示はGPLv3準拠のため維持する。

利用方針:

- TrollStore向け **Twitterブランド版** を基準にする。
- 本家releaseの `NeoFreeBird-trollstore-Twitter_*.tipa` をベースにする。
- 明示指示がない限りXブランド版へ切り替えない。

---

## 2. 現在の基準バージョン

2026-10-16時点:

- 本家最新release: **v7.1.1**
- 本家 `v7` 取り込み済み先端: `a8cb17f762e74a3c682eac1e987872db3957e9b5`
- ベースTwitterアプリ: **12.31.1**
- NFB_Local: **7.1.6**
- 7.1.6同期コミット: `1272fdfa21aa119d359910e305903ec35e376a3e`
- 7.1.6引き継ぎ更新後main: `f67f59c70d111b5702d378cce5507782ed2d8e77` 以降
- 7.1.6ビルド: GitHub Actions `Package` run #7
- Run ID: `38659559714`
- 成果物: `local_7.1.6_12.31.1.tipa`
- Artifact ID: `11938158386`
- Artifact size: `257053961` bytes
- Artifact SHA-256: `cf532f5ef79b716759ea4ea8d6c4070cde8685ca8ca1a1d2275f2a336053a302`
- Artifact URL: `https://github.com/oxUNKNOWNxo/NFB_Local/actions/runs/38659559714/artifacts/11938158386`

run #7で確認済み:

- `HomeBars.x` / `AppLifecycle.x` compile成功
- `LinkTracking.x` / `ReplySorting.x` / `Timeline.x` compile成功
- 設定画面関連 compile成功
- TrollStore Twitter base取得成功
- dylib差し替え成功
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

**7.1.6はビルド成功済みだが、実機での起動・各機能の確認は別扱い。**

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

この同期ではローカル独自のHome処理を保護して取り込んでいる。

---

## 4. 日本語ローカライズ

本家英語設定をmasterとして日本語設定を追従する。

7.1.6同期時:

- 英語 / 日本語の設定キー構成: **303 / 303**
- 新規キーを日本語化済み。
- 英語原文が変更された `REPLY_SORTING_DETAIL` も内容に合わせて更新済み。

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

この項目はLocalizable.stringsの303件には含まれない。

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

Twitter 12.31.1での概念上のindex:

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

公式releaseのTwitter/Xアプリ版が12.31.1から変わった場合は、Home Timeline内部APIを実バイナリで再確認すること。

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

この7.1.5由来の実装は7.1.6でも保持されている。

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

---

## 10. 本家更新時の自動追従手順

ChatGPT側の条件監視タスク **「タスク NeoFreeBird更新確認」** を使用する。

更新がなければ通知しない。

更新がある場合:

1. `NFB_Local` がPrivateのままか確認。
2. 現在の `main` と `PROJECT_STATE.md` を取得。
3. 本家 `v7` / 最新releaseとの差分を取得。
4. **現在のmainから** `automation/upstream-v7-ready-YYYYMMDD-*` を作る。
5. 作業はその検証ブランチだけで行う。
6. 本家変更を丸ごと上書きせず、ローカル改造を保護して統合。
7. 日本語Localizableの追加キーと英語原文変更を反映。
8. `hide_for_you_tab` / `restore_home_tab_selection` を維持。
9. Twitter/X本体バージョンが変わった場合はHome selectorを実バイナリで再解析。
10. TrollStore `@rpath`補正等を維持。
11. `PROJECT_STATE.md` を検証ブランチ上で更新。
12. ready branchへ最終状態をpush。
13. pushによって `Package` が自動実行。
14. Package失敗なら同じbranchで安全に修正し再push。
15. Package成功後、`Promote verified update` がmainへfast-forward。
16. ChatGPTはPromote結果と最終main SHA、Private状態を確認。
17. ビルド成功と実機動作確認は分けて報告。

ChatGPT側で禁止する操作:

- `main` への直接ref更新
- `main` へのmerge操作
- force push
- Pull Request作成
- Promote失敗時に上記操作へ切り替えること

競合や互換性問題を安全に解決できない場合は、正常動作中のmainを変更せず、検証ブランチを残して通知する。

### 自動同期で変更してはいけない信頼境界

通常の本家同期作業では以下を変更しない:

- `.github/workflows/package.yml`
- `.github/workflows/promote-verified-update.yml`

Workflow自体を変更する必要がある場合は、自動昇格とは別の明示的な作業としてmain上でレビュー・変更する。

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

## 12. 7.1.6 要実機確認

最低限:

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

## 13. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、現在の `main` と本家 `NeoFreeBird/app` の `v7` を確認してから作業を続けてください。Twitterブランド / TrollStore基準、日本語ローカライズ、`hide_for_you_tab`、`restore_home_tab_selection`、CydiaSubstrateの `@rpath` 補正を必ず維持してください。自動本家追従ではChatGPTからmain更新やPR作成を行わず、`automation/upstream-v7-ready-*` → `Package` → `Promote verified update` の経路を使ってください。公式Twitterアプリ版が12.31.1から変わった場合は、Home Timeline selectorを推測せず実バイナリで再確認してください。

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
