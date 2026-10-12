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
- NFB_Local: **7.1.3**
- 最新ビルド候補: `local_7.1.3_12.31.1.tipa`
- GitHub Actions: `Package` run #4
- Run ID: `38281189165`
- Artifact ID: `11760958389`
- Artifact size: `257037479` bytes
- Artifact SHA-256:
  `dd2a73e436135f4bffc29ccfed23865bf4e9fec0cbc289cd991c599dd899f54d`

### 検証状態

run #4で以下は成功済み:

- Source compile
- `HomeBars.x` compile
- TrollStore base取得
- dylib差し替え
- CydiaSubstrate dependency補正
- Mach-O install name維持
- `ldid`署名
- ZIP integrity check
- Artifact upload

`local_7.1.3_12.31.1.tipa` の**実機での再起動時タブ選択修正は未検証**。
ユーザーの実機確認後にこの記述を更新すること。

直前の実機確認済み版:

- `local_7.1.2_12.31.1.tipa`
- 起動成功
- 「おすすめ」非表示自体は設定ON/OFF後に機能
- ただし再起動時に2つ目の固定/カスタムタイムラインが選択される問題を確認

---

## 3. 日本語ローカライズ

本家英語設定をmasterとして、日本語設定を追従する。

過去の検査結果:

- `ja` = **293/293 translated (100%)**

主要ファイル:

- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`

更新時の確認:

```bash
./check_localization.py ja
./check_localization.py ja --values
```

本家更新で:

- 新規設定キー
- 英語文言変更
- 日本語欠落
- 英語のまま残った値

を確認し、日本語へ補完する。

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

設定定義:

- `src/Core/BHTSettings.m`

設定画面イベント:

- `src/Settings/Pages/TimelinesSettingsViewController.m`

フック本体:

- `src/Hooks/HomeBars.x`

日本語表示:

- タイトル: `「おすすめ」タブを非表示`
- 説明: おすすめだけを除外し、Followingと固定/カスタムタイムラインを維持する趣旨。

### 4.1 X 12.31.1の基本実装

X/Twitter 12.31.1本体を実際に解析し、Home Timelineの現行selectorを確認した。
XNotForMeのX 12.3向けコードだけを根拠にしないこと。

主な12.31.1 selector:

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

互換目的で旧12.3系も残している:

- `numberOfTabsV1In:`
- `numberOfTabsV2In:`
- `unifiedSegmentedController:...`

### 4.2 タブのindex変換

12.31.1では概念上:

- source index 0 = For You / おすすめ
- source index 1 = Following / フォロー中
- source index 2以降 = pinned/custom timelines

`hide_for_you_tab` ON時:

- `numberOfTabsIn:` は1つ減らす。
- visible index N は source index N+1 へ渡す。

したがって表示上:

- visible 0 -> source 1 = Following
- visible 1 -> source 2 = 1つ目の固定/カスタムtimeline
- visible 2 -> source 3 ...

この**visible index と source index の区別が最重要**。

### 4.3 7.1.2で発生した再起動時の選択ずれ

実機報告:

- おすすめ非表示は機能する。
- しかしアプリを再起動すると、Followingではなく**2つ目の表示タブ（最初の固定/カスタムtimeline）**が選択された状態で開く。

原因:

7.1.2では、上記のindex remapに加えて:

- `THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier = latest`
- lifecycle時に `selectTimelineVariant(..., 1, ...)` 相当でFollowingを強制

という「source index 1を選ぶ」処理も行っていた。

For Youを削除した後のvisible stripではFollowingはvisible index 0であり、`1` を重ねて強制すると復元経路によってはvisible index 1として扱われ、次のtimelineへずれる。

### 4.4 7.1.3の修正

7.1.3では、**表示indexのremapを唯一の基準**にする。

変更点:

- lifecycleでvariant 1を積極的に強制する処理を削除。
- `latest` を保存して復元させる方式を削除。
- `ClearHiddenHomeSelection()` を追加。
- `hide_for_you_tab` ON時は
  `THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier`
  を削除する。
- `viewDidLoad` の `%orig` より前に保存済み選択を削除する。
- X側にはshortened stripのvisible index 0から初期化させる。
- visible index 0はDataSource remapによりsource index 1 (Following)になる。
- `viewDidAppear:` ではvariant 1を強制せず、保存済み選択だけをクリアする。
- 設定ON/OFF時は `applyHideForYouSetting()` から選択状態クリア + segmented controller reloadを行う。

なお、X内部が明示的にalgorithmic variant 0を要求した場合の:

- `selectTimelineVariant:shouldRefresh:`
- `selectFilteredTimelineVariant:shouldRefresh:`

の `0 -> 1` リダイレクトは残している。

**もし7.1.3でも再起動時に2つ目のtimelineへずれる場合、次に疑うのはこのvariant redirectか、LegacySegmented controller側のselected-index復元処理。推測で追加修正せず、12.31.1本体からselected/select/index系selectorを追加解析すること。**

### 4.5 設定画面側

`TimelinesSettingsViewController.m` は現在:

- `hide_custom_timelines` -> `applyHideCustomTimelinesSetting()`
- `hide_for_you_tab` -> `applyHideForYouSetting()`

だけを呼ぶ。

古い `setObject:@"latest"` 処理は残っていない。

---

## 5. TrollStoreパッケージング — 絶対に維持する処理

### 5.1 過去の起動直後クラッシュ

初期実装では、本家Twitter TrollStore `.tipa` を展開し、新しくビルドした `BHTwitter.dylib` を単純差し替えした。
その結果、アイコンタップ直後にクラッシュした。

比較結果:

本家配布版:

```text
@rpath/CydiaSubstrate.framework/CydiaSubstrate
```

Theos新規build:

```text
/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
```

本家TrollStore版では `CydiaSubstrate.framework` はアプリ内 `Frameworks` にあるため、新規dylibの絶対パス依存はdyldクラッシュ原因になる。

### 5.2 正しいAssemble処理

`.github/workflows/package.yml` で必ず以下を行う:

1. 本家Twitter TrollStore `.tipa` を展開。
2. 元 `BHTwitter.dylib` からCydiaSubstrate dependencyを取得。
3. 元dylibのMach-O install nameも取得。
4. 新規 `BHTwitter.dylib` を差し替え。
5. `install_name_tool` でdependencyを本家と同一に補正。
6. install nameも本家と同一にする。
7. `ldid -S` でdylibを署名。
8. `otool` で補正結果を検証。
9. `BHTwitter.bundle` をローカル版へ差し替え。
10. Info.plistから以下を削除:
    - `TSPreAppliedExploitType`
    - `TSBundlePreSigned`
11. `.tipa`へ再ZIP。
12. `unzip -tq` でintegrity check。

7.1.3 / run #4でも確認済み:

```text
Base substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
Built substrate dependency: /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
Patched substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
```

この処理を削除したり、単純なdylib差し替えへ戻してはいけない。

---

## 6. Package Workflow

ファイル:

- `.github/workflows/package.yml`

Actions表示名:

- `Package`

通常トリガー:

- `workflow_dispatch` のみ

検証目的で一時的にpush triggerを追加する場合は、ビルド完了後必ず削除してmanual-onlyへ戻す。

### ベース選択

本家releaseから以下に一致するassetだけを選ぶ:

```regex
^NeoFreeBird-trollstore-Twitter_.*\.tipa$
```

`base_tag` 空欄時は本家latest release。
必要なら特定tagを指定可能。

### 出力名

```text
local_<NFB_Local Version>_<Twitter App Version>.tipa
```

例:

```text
local_7.1.3_12.31.1.tipa
```

---

## 7. 本家更新時の追従手順

本家 `NeoFreeBird/app` にrelease/source updateがあった場合:

1. 現在のNFB_Localと本家v7の差分を確認。
2. 本家変更を丸ごと上書きしない。
3. 本家の修正・新機能を取り込む。
4. ローカル独自変更を再適用/維持。
5. 英語Localizableと日本語Localizableを比較して新規・変更設定を日本語化。
6. `check_localization.py ja` / `ja --values` を実行。
7. `hide_for_you_tab` を維持。
8. 新しいTwitter/XバージョンでHome Timeline内部APIが変わっていれば実バイナリを解析して適応。
9. TrollStore `@rpath`補正等のPackage処理を維持。
10. Compile / Assemble / Artifact生成まで確認。
11. 重要な結果をこの `PROJECT_STATE.md` に反映。

特に競合確認するファイル:

- `src/Hooks/HomeBars.x`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`
- `src/Hooks/FeatureSwitches.x`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `.github/workflows/package.yml`
- `control`

### Home Timeline互換性

古いselectorを盲目的に再利用しない。
新しいbase `.tipa` 内のTwitter Mach-Oから必要に応じて:

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

不可。
CydiaSubstrate dependencyが `/Library/Frameworks/...` のままになり、起動直後クラッシュした。
必ず本家の `@rpath/...` へ補正する。

### 9.2 TrollStore再署名だけを原因と決めつけない

過去に署名だけが原因と仮定したが、それだけでは直らなかった。
起動直後クラッシュ時はまず:

```bash
otool -L BHTwitter.dylib
otool -D BHTwitter.dylib
```

で本家dylibと比較する。

### 9.3 XNotForMeの対応版を混同しない

XNotForMeの公開実装はX 12.3向け。
NFB_Localの現行baseはTwitter/X 12.31.1。
外部tweakのselectorをそのまま現行版とみなさず、必要なら実バイナリで確認する。

### 9.4 source indexとvisible indexを混同しない

For Youを削除すると:

- Followingはsource index 1
- しかしvisible index 0

になる。

複数timelineを残す設計では、source index 1を「選択index 1」として強制してはいけない。
7.1.2の再起動時選択ずれはこの設計ミスが原因と考えられる。

---

## 10. 現在の既知課題 / 要実機確認

1. **7.1.3再起動時選択修正**
   - build成功。
   - 実機確認待ち。
   - 期待動作: おすすめ非表示ONで再起動してもFollowing（先頭の表示タブ）から開始する。

2. **初回/設定変更直後のUI反映**
   - 過去版では設定ON/OFF後に非表示が確実に反映された。
   - 7.1.3では `applyHideForYouSetting()` でreloadする。
   - 新規インストール時のdefaultはOFFなので、初期状態でFor Youが見えること自体は仕様。

3. **本家更新時の内部API変更**
   - 新Twitter/X版でselectorが変わる可能性あり。
   - 必要なら毎回実バイナリを確認する。

---

## 11. 次チャット開始時の推奨指示

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、その内容を基準に現在のmainを確認してから作業を続けてください。特にTrollStoreの@rpath補正、Twitterブランド基準、hide_for_you_tabのvisible/source index設計を維持し、過去の単純dylib差し替え方式や古いHome Timeline selectorへ戻さないでください。

---

## 12. 更新ルール

NFB_Localへ重要な修正を行った場合は、同じ作業内でこの `PROJECT_STATE.md` も更新する。

特に更新する項目:

- 本家NeoFreeBirdバージョン
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新build / Artifact ID / SHA-256
- `hide_for_you_tab` の互換実装
- Package方式の変更
- 新しい既知問題
- 解決済み問題
- 実機検証結果
