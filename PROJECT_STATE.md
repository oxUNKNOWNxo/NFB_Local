# NFB_Local — PROJECT_STATE

最終更新: 2026-10-13 (JST)

このファイルは、ChatGPTの別チャットや将来の作業へ `NFB_Local` の状態・設計判断・既知問題を引き継ぐための基準資料。
作業開始時は、まずこのファイルと現在の `main` を確認すること。

---

## 1. リポジトリ / 基本方針

- ローカル改修先: `oxUNKNOWNxo/NFB_Local`
- 可視性: **Private**
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

2026-10-13時点:

- 本家 NeoFreeBird: **7.1.1**
- ベースTwitterアプリ: **12.31.1**
- NFB_Local: **7.1.5**
- 最新ビルド: `local_7.1.5_12.31.1.tipa`
- GitHub Actions: `Package` run #6
- Run ID: `38317396560`
- Artifact ID: `11776887465`
- Artifact size: `257040932` bytes
- Artifact SHA-256:
  `82a79ccadcc5e09682a76d1552ba6b8ed92a832668364ce11a777f60294e99fc`

### build検証状態

run #6で以下は成功済み:

- Source compile
- `HomeBars.x` compile
- `AppLifecycle.x` compile
- 設定画面追加部分 compile
- TrollStore Twitter base取得
- dylib差し替え
- CydiaSubstrate dependency補正
- Mach-O install name維持
- `ldid`署名
- ZIP integrity check
- Artifact upload

`Package` は検証時のみpush triggerを一時追加し、run #6開始後に **workflow_dispatchのみ**へ戻してある。

`local_7.1.5_12.31.1.tipa` のHome選択挙動は**実機確認待ち**。

---

## 3. 日本語ローカライズ

本家英語設定をmasterとして、日本語設定を追従する。

過去の検査結果:

- `ja` = **293/293 translated (100%)**

主要ファイル:

- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`

更新時:

```bash
./check_localization.py ja
./check_localization.py ja --values
```

を確認する。

固有名詞 (`NeoFreeBird`, `Grok`, `OK` 等) は必要がなければ翻訳しない。

このプロジェクトで追加した主な日本語:

- `HIDE_FOR_YOU_TAB_TITLE`
- `HIDE_FOR_YOU_TAB_DETAIL`
- macOSアプリアイコン変更エラー文
- その他不足していた設定文字列

### 3.1 `restore_home_tab_selection` の表示文字列

7.1.5で追加したローカル設定 `restore_home_tab_selection` は、本家共通設定レジストリとの競合を避けるため、`TimelinesSettingsViewController.m` からページへ直接追加している。

同ファイル内で:

- 日本語: `選択したホームタブを復元`
- 英語: `Restore selected Home tab`

を表示する。

この1項目は現時点では `Localizable.strings` ではなくページ側のローカル文字列なので、`check_localization.py` の293件には含まれない。

---

## 4. 「おすすめ」タブ非表示

追加設定キー:

- `hide_for_you_tab`

現在のdefault:

- **OFF**

ユーザーから明示指示がない限り勝手にdefault ONへ変更しない。

主要ファイル:

- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`
- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Hooks/HookHelpers.h`

日本語表示:

- タイトル: `「おすすめ」タブを非表示`
- おすすめだけを除外し、Followingと固定/カスタムタイムラインを維持する。

### 4.1 X/Twitter 12.31.1のタブindex設計

実バイナリ解析結果を基準とする。
XNotForMeなど旧版向けtweakのselectorだけを根拠にしない。

概念上:

- source index 0 = For You / おすすめ
- source index 1 = Following / フォロー中
- source index 2以降 = pinned/custom timelines

`hide_for_you_tab` ON時は:

- `numberOfTabsIn:` を1つ減らす。
- visible index N -> source index N+1へ変換する。

したがって:

- visible 0 -> source 1 = Following
- visible 1 -> source 2 = 最初の固定/カスタムtimeline
- visible 2 -> source 3 ...

**visible indexとsource indexを混同しないこと。**

12.31.1で確認済みの主なselector:

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
- `selectedViewController`
- `segmentedViewController:willSelectViewController:atIndex:indexChanged:`
- `segmentedViewController:didSelectViewController:atIndex:previousIndex:trigger:`

互換目的で旧12.3系の `numberOfTabsV1In:` / `numberOfTabsV2In:` / `unifiedSegmentedController:...` も残している。

### 4.2 7.1.2 — 再起動時選択ずれ

実機で:

- おすすめ非表示は機能。
- 再起動するとFollowingではなく**表示上2番目のタブ（最初の固定/カスタムtimeline）**が選択された。

source index 1とvisible index 1を混同する経路が疑われた。

### 4.3 7.1.3 — 保存キー削除では直らなかった

7.1.3では:

- lifecycleでvariant 1を強制する処理を削除。
- `latest` 保存を削除。
- `THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier` を削除。
- `viewDidLoad` / `viewDidAppear` で保存選択をクリア。

とした。

**実機結果: 失敗。**

7.1.3でも再起動後に表示上2番目のタブが選択された。

結論:

- NSUserDefaultsの保存キー削除だけでは不十分。
- `LegacySegmentedViewController` 側のvisible indexも扱う必要がある。

### 4.4 7.1.4 — `reloadDataWithSelectingIndex:0`

7.1.4ではHome初回表示時に一度だけ:

```text
reloadDataWithSelectingIndex:0
```

を実行した。

実機結果:

- 通常の別画面へ移動してHomeへ戻っただけでは、固定リストから勝手にFollowingへ戻る副作用は確認されなかった。
- ただし、別アプリを起動して戻った場合またはアプリ再起動など、条件未確定のタイミングで**依然として表示上2番目のタブが先頭表示になることがあった**。

したがって7.1.4の「containerごとに1回だけ0へ補正」は不十分。

### 4.5 7.1.5 — コールド起動と復帰を分離

ユーザー指示:

1. **アプリの初期起動時は必ずFollowingを選択する。**
2. 選択した固定リストを復元する機能は独立した設定項目にする。

追加設定キー:

```text
restore_home_tab_selection
```

仕様:

- 初期値: **OFF**
- `hide_for_you_tab` の子設定として表示。
- `hide_for_you_tab` がOFFなら設定行自体を隠す。
- コールド起動時は設定ON/OFFにかかわらず必ず visible index 0 = Following。
- 選択indexは**プロセス内static変数だけ**に保持し、NSUserDefaultsへ永続化しない。
- よってアプリを完全終了すると記録は消え、次回は必ずFollowingから開始する。

復元設定OFF:

- バックグラウンドから復帰した場合もFollowingへ戻す。

復元設定ON:

- `applicationWillResignActive:` で、Twitter本体の `%orig` より**前**に `LegacySegmentedViewController.currentIndex` を取得。
- 現在のvisible indexを `HomeSessionVisibleIndex` に保存。
- `applicationDidBecomeActive:` のTwitter本体 `%orig` 完了後に、main queue次turnで `reloadDataWithSelectingIndex:<saved visible index>` を実行。
- 同一プロセス内だけ、手動選択した固定/カスタムtimelineを復元する。

初回Home構築:

- `HomeColdLaunchSelectionApplied == NO` なら必ずtarget index 0。
- 初回補正後に `HomeColdLaunchSelectionApplied = YES`。
- 後からHome containerが再生成された場合のみ、復元設定ONならsession indexを使える。

設定ON/OFFを変更した際:

- ON: 現在のvisible indexをsession記録に取り込む。
- OFF: session記録を0へ戻し、その場でFollowingへ戻す。

実機確認はまだ。

### 4.6 設定画面実装

`TimelinesSettingsViewController.m` は:

- `hide_custom_timelines` -> `applyHideCustomTimelinesSetting()`
- `hide_for_you_tab` -> `applyHideForYouSetting()`
- `restore_home_tab_selection` -> `applyRestoreHomeTabSelectionSetting()`

`restore_home_tab_selection` は本家 `BHTSettingsPages()` を直接変更せず、`-buildSettingsList` overrideで `hide_for_you_tab` の直後へ挿入する。

理由:

- ローカル専用機能を本家共通registryから分離する。
- 本家更新時のmerge競合を減らす。

---

## 5. TrollStoreパッケージング — 絶対に維持する処理

過去に本家Twitter TrollStore `.tipa` 内の `BHTwitter.dylib` を単純差し替えしたところ起動直後クラッシュした。

原因となった差:

本家配布版:

```text
@rpath/CydiaSubstrate.framework/CydiaSubstrate
```

Theos新規build:

```text
/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
```

したがって `.github/workflows/package.yml` では必ず:

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

を維持する。

単純dylib差し替え方式へ戻してはいけない。

---

## 6. Package Workflow

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
local_7.1.5_12.31.1.tipa
```

---

## 7. 本家更新時の追従手順

本家 `NeoFreeBird/app` にrelease/source updateがあった場合:

1. 現在のNFB_Localと本家v7の差分を確認。
2. 本家変更を丸ごと上書きしない。
3. 本家の修正・新機能を取り込む。
4. ローカル独自変更を維持。
5. 英語Localizableと日本語Localizableを比較し日本語化。
6. `check_localization.py ja` / `ja --values` を確認。
7. `hide_for_you_tab` と `restore_home_tab_selection` を維持。
8. 新Twitter/X版でHome Timeline内部APIが変わっていれば実バイナリを解析。
9. TrollStore `@rpath`補正等を維持。
10. Compile / Assemble / Artifact生成まで確認。
11. この `PROJECT_STATE.md` を更新。

特に競合確認するファイル:

- `src/Hooks/HomeBars.x`
- `src/Hooks/AppLifecycle.x`
- `src/Hooks/HookHelpers.h`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`
- `src/Hooks/FeatureSwitches.x`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `.github/workflows/package.yml`
- `control`

Home Timelineは古いselectorを盲目的に再利用せず、必要ならbase `.tipa` の実バイナリから:

- HomeTimelineContainer
- `numberOfTabs*`
- segmented controller
- selected/select/index/currentIndex
- TimelineVariant
- Following / ForYou / latest

を直接確認する。

---

## 8. 自動更新監視

ChatGPT側に条件監視タスク **「NeoFreeBird追従更新」** を設定済み。

方針:

- 本家更新がなければ通知しない。
- 更新があればNFB_Localへ取り込み。
- 日本語化を更新。
- `hide_for_you_tab` / `restore_home_tab_selection` を維持し、必要なら新Twitter版へ適応。
- TrollStore Package/buildまで進める。
- 安全に解決できない競合は動作中の版を壊さず通知する。

---

## 9. 過去の重要な失敗 / 戻してはいけない点

### 9.1 単純dylib差し替え

不可。必ず本家の `@rpath/...` へ補正する。

### 9.2 TrollStore再署名だけを原因と決めつけない

起動直後クラッシュ時はまず:

```bash
otool -L BHTwitter.dylib
otool -D BHTwitter.dylib
```

で本家dylibと比較する。

### 9.3 XNotForMeの対応版を混同しない

外部tweakのselectorを現行12.31.1と決めつけず、必要なら実バイナリで確認する。

### 9.4 source indexとvisible indexを混同しない

For Youを削除するとFollowingは:

- source index 1
- visible index 0

になる。

### 9.5 7.1.3の保存キー削除方式へ戻さない

`lastSelectedTimelineTabIdentifier` の削除だけでは2番目選択は直らなかった。
12.31.1ではLegacySegmented側のvisible indexも明示的に扱う必要がある。

### 9.6 7.1.4のcontainer一回補正だけへ戻さない

`reloadDataWithSelectingIndex:0` をHome container初回表示時に一度呼ぶだけでは、バックグラウンド復帰/再生成等で2番目へずれる現象が残った。

7.1.5以降はApp lifecycleを跨いでvisible indexを扱う。

---

## 10. 現在の既知課題 / 要実機確認

1. **7.1.5 コールド起動**
   - `hide_for_you_tab` ONで完全終了→起動した際、必ずFollowing（表示上先頭）で開くこと。

2. **復元設定OFF**
   - 固定リストを選択→別アプリへ移動→戻るとFollowingへ戻ること。

3. **復元設定ON**
   - 固定リストを選択→別アプリへ移動→戻ると同じ固定リストへ戻ること。
   - その後アプリを完全終了→再起動すると、固定リストではなくFollowingから始まること。

4. **通常の画面遷移**
   - Home以外のTwitter内画面へ移動して戻っただけで、不必要にFollowingへ戻されないこと。

5. **本家更新時の内部API変更**
   - 新Twitter/X版でselectorが変わる可能性あり。

---

## 11. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、その内容を基準に現在のmainを確認してから作業を続けてください。特にTwitterブランド基準、TrollStoreの@rpath補正、hide_for_you_tabのvisible/source index設計、7.1.5の「コールド起動は必ずFollowing・固定リスト復元は任意かつ同一セッションのみ」という仕様を維持してください。過去の単純dylib差し替え、保存キー削除だけの7.1.3、container初回一度だけ補正する7.1.4へ戻さないでください。

---

## 12. 更新ルール

重要な修正を行った場合は同じ作業内でこの `PROJECT_STATE.md` を更新する。

特に:

- 本家NeoFreeBirdバージョン
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新build / Artifact ID / SHA-256
- `hide_for_you_tab` / `restore_home_tab_selection` の互換実装
- Package方式の変更
- 新しい既知問題
- 解決済み問題
- 実機検証結果

を最新状態に保つ。
