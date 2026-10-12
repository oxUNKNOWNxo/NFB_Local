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
- NFB_Local: **7.1.4**
- 最新ビルド: `local_7.1.4_12.31.1.tipa`
- GitHub Actions: `Package` run #5
- Run ID: `38297480481`
- Artifact ID: `11768374907`
- Artifact size: `257038679` bytes
- Artifact SHA-256:
  `1570e63af09b809b429de92a94b25fb96948874881dda5075afe8543458164a4`

### build検証状態

run #5で以下は成功済み:

- Source compile
- `HomeBars.x` compile
- TrollStore Twitter base取得
- dylib差し替え
- CydiaSubstrate dependency補正
- Mach-O install name維持
- `ldid`署名
- ZIP integrity check
- Artifact upload

確認されたdependency:

```text
Base substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
Built substrate dependency: /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
Patched substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
```

`local_7.1.4_12.31.1.tipa` の**再起動時Home選択修正は実機確認待ち**。

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

12.31.1で利用中の主なselector:

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

互換目的で旧12.3系の `numberOfTabsV1In:` / `numberOfTabsV2In:` / `unifiedSegmentedController:...` も残している。

### 4.2 7.1.2 — 再起動時選択ずれ

実機で:

- おすすめ非表示は機能。
- 再起動するとFollowingではなく**表示上2番目のタブ（最初の固定/カスタムtimeline）**が選択された。

7.1.2ではsource index 1をFollowingとして強制する処理があり、For You除去後のvisible index 1として解釈される経路があった。

### 4.3 7.1.3 — 保存キー削除では直らなかった

7.1.3では:

- lifecycleでvariant 1を強制する処理を削除。
- `latest` 保存を削除。
- `THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier` を削除。
- `viewDidLoad` / `viewDidAppear` で保存選択をクリア。

とした。

**実機結果: 失敗。**

ユーザー確認では7.1.3でも再起動後に表示上2番目のタブが選択された。

結論:

- 問題の主因はNSUserDefaultsの保存キーではない。
- `LegacySegmentedViewController` 側が独立してvisible index 1を保持/復元している可能性が高い。

### 4.4 7.1.4 — LegacySegmented側のvisible indexを明示補正

12.31.1本体を追加解析し、選択関連として以下を確認した:

- `reloadDataWithSelectingIndex:`
- `selectTabAtIndex:`
- `currentIndex`
- `selectedViewController`
- `segmentedViewController:willSelectViewController:atIndex:indexChanged:`
- `segmentedViewController:didSelectViewController:atIndex:previousIndex:trigger:`
- `selectedTabIndex`
- `setSelectedIndex:`
- `setSelectedIndex:animated:`

このうち7.1.4では、意味が明確でruntime確認も可能な **`reloadDataWithSelectingIndex:`** を採用した。

`ReloadHomeTimelineTabs()` は `hide_for_you_tab` ON時:

```text
reloadDataWithSelectingIndex:0
```

を `respondsToSelector:` で存在確認してから呼ぶ。

visible index 0は既存DataSource remapによりsource index 1 = Followingとなる。

さらに起動時は:

- `viewDidAppear:` 完了後
- main queueの次のrun-loop turn
- Home containerインスタンスごとに**一度だけ**

この補正を実行する。

一度限りにしている理由:

- Homeへ戻るたびに0番を強制すると、ユーザーが手動選択した固定/カスタムtimelineから毎回Followingへ戻されてしまうため。

設定をONへ切り替えた際の `applyHideForYouSetting()` も同じreload/select処理を使い、即時にFollowingを先頭表示する。

なお、X内部がalgorithmic variant 0を要求した場合の:

- `selectTimelineVariant:shouldRefresh:`
- `selectFilteredTimelineVariant:shouldRefresh:`

の `0 -> 1` リダイレクトは引き続き残す。

### 4.5 設定画面側

`TimelinesSettingsViewController.m` は:

- `hide_custom_timelines` -> `applyHideCustomTimelinesSetting()`
- `hide_for_you_tab` -> `applyHideForYouSetting()`

のみ。

古い `setObject:@"latest"` は残っていない。

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
local_7.1.4_12.31.1.tipa
```

一時的な `.run_package` / Home診断workflow / 診断triggerは7.1.4作業終了時点で削除済み。

---

## 7. 本家更新時の追従手順

本家 `NeoFreeBird/app` にrelease/source updateがあった場合:

1. 現在のNFB_Localと本家v7の差分を確認。
2. 本家変更を丸ごと上書きしない。
3. 本家の修正・新機能を取り込む。
4. ローカル独自変更を維持。
5. 英語Localizableと日本語Localizableを比較し日本語化。
6. `check_localization.py ja` / `ja --values` を確認。
7. `hide_for_you_tab` を維持。
8. 新Twitter/X版でHome Timeline内部APIが変わっていれば実バイナリを解析。
9. TrollStore `@rpath`補正等を維持。
10. Compile / Assemble / Artifact生成まで確認。
11. この `PROJECT_STATE.md` を更新。

特に競合確認するファイル:

- `src/Hooks/HomeBars.x`
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
- selected/select/index
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
- `hide_for_you_tab` を維持・必要なら新Twitter版へ適応。
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

`lastSelectedTimelineTabIdentifier` の削除だけでは再起動時の2番目選択は直らなかった。
12.31.1ではLegacySegmented側のvisible indexも明示的に扱う必要がある。

---

## 10. 現在の既知課題 / 要実機確認

1. **7.1.4 再起動時選択修正**
   - build/package成功。
   - 実機確認待ち。
   - 期待動作: おすすめ非表示ONでアプリを完全終了→再起動した際、Following（表示上先頭）で開く。
   - 固定/カスタムtimelineを手動選択した後、通常の画面遷移で勝手にFollowingへ戻らないことも確認する。

2. **初回/設定変更直後のUI反映**
   - `applyHideForYouSetting()` がreloadを行う。
   - defaultはOFFなので新規インストール直後にFor Youが見えること自体は仕様。

3. **本家更新時の内部API変更**
   - 新Twitter/X版でselectorが変わる可能性あり。

---

## 11. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、その内容を基準に現在のmainを確認してから作業を続けてください。特にTrollStoreの@rpath補正、Twitterブランド基準、hide_for_you_tabのvisible/source index設計と7.1.4のreloadDataWithSelectingIndex:0による初期選択補正を維持し、過去の単純dylib差し替え方式や7.1.3の保存キー削除だけの方式へ戻さないでください。

---

## 12. 更新ルール

重要な修正を行った場合は同じ作業内でこの `PROJECT_STATE.md` を更新する。

特に:

- 本家NeoFreeBirdバージョン
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新build / Artifact ID / SHA-256
- `hide_for_you_tab` の互換実装
- Package方式の変更
- 新しい既知問題
- 解決済み問題
- 実機検証結果

を最新状態に保つ。
