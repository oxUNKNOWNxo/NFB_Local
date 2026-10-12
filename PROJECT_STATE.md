# NFB_Local — PROJECT_STATE

最終更新: 2026-10-13 (JST)

このファイルは、ChatGPTの別チャットや将来の作業へ `NFB_Local` の状態・設計判断・既知問題を引き継ぐための基準資料。
作業開始時は、まずこのファイルと現在の `main` を確認すること。

---

## 1. リポジトリ / 方針

- ローカル改修先: `oxUNKNOWNxo/NFB_Local`
- 現在の可視性: **Private**
- デフォルトブランチ: `main`
- 本家: `NeoFreeBird/app`
- 本家基準ブランチ: `v7`
- 本家とはGitHub上のFork関係を持たない独立リポジトリとして作成した。
- `README.md` は意図的に空白化している。
- GitHub上で目立つ名称を減らすため、Actionsは中立名の `Package` を主用途としている。
- LICENSE / 著作権表示はGPLv3準拠のため維持すること。

### ユーザーの利用環境 / 必須方針

- 利用方法: **TrollStore**
- パッケージ基準: **Twitterブランド版**
- Xブランド版ではなく、本家リリース内の `NeoFreeBird-trollstore-Twitter_*.tipa` を基準にする。
- 今後もTwitter版を優先し、X版へ切り替えないこと。

---

## 2. 現在の基準バージョン

このPROJECT_STATE作成時点:

- 本家 NeoFreeBird: **7.1.1**
- ベースTwitterアプリ: **12.31.1**
- NFB_Local control version: **7.1.2**
- 最新の確認済みビルド: `local_7.1.2_12.31.1.tipa`
- GitHub Actions: `Package` run #3
- Artifact ID: `11758656217`
- Artifact SHA-256:
  `0a3b5caaed173b9b23811f5c0d2f0b5440773b923bbf69686d5cd7cdffdcda97`

この値は将来の本家更新後には古くなる。更新時はこの章も更新すること。

---

## 3. このプロジェクトで追加した主な機能

### 3.1 設定画面の日本語化

本家の日本語ローカライズを点検し、英語側とのキー差分を埋めた。

当時の検査結果:

- `ja` = **293/293 (100%)**

補完した例:

- macOSアプリアイコン変更関連エラー文
- `Cool kids`
- 新規追加した「おすすめ」非表示設定

日本語化の基準:

- 英語 `Localizable.strings` をmasterとして扱う。
- `check_localization.py` を使用する。
- 更新時は少なくとも以下を確認すること。

```bash
./check_localization.py ja
./check_localization.py ja --values
```

- 新規キー、空値、英語のまま残った値を確認し、日本語へ補完する。
- 固有名詞 (`NeoFreeBird`, `Grok`, `OK` 等) は無理に翻訳しない。

主要ファイル:

- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`

---

### 3.2 ホームの「おすすめ」タブ非表示

追加設定キー:

- `hide_for_you_tab`

日本語表示:

- タイトル: `「おすすめ」タブを非表示`
- 説明: ホームタイムラインから「おすすめ」を除外し、「フォロー中」および固定/カスタムタイムラインを維持する趣旨。

現在の初期値:

- **OFF**

設定定義:

- `src/Core/BHTSettings.m`

設定切り替え処理:

- `src/Settings/Pages/TimelinesSettingsViewController.m`

ホームフック本体:

- `src/Hooks/HomeBars.x`

#### 実装方針

単純にビューを隠すのではなく、ホームのタブDataSourceで「おすすめ」に対応するsource index 0を除外し、表示側indexを `+1` してsourceへ渡す。

これにより:

- おすすめ = 非表示
- フォロー中 = 維持
- 固定/カスタムタイムライン = 維持

を狙う。

さらに:

- `selectTimelineVariant:shouldRefresh:` でおすすめ (variant 0) を要求された場合、Following (variant 1) へリダイレクト。
- `THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier` を `latest` に設定。
- 設定ON時は `applyHideForYouSetting()` からタブ再読込。
- `viewDidAppear:` でもFollowing選択を再適用。

#### X 12.31.1で確認した現行セレクタ

X 12.31.1本体をActions上で直接診断して確認した。
旧XNotForMe (X 12.3向け) のみを根拠にしないこと。

12.31.1で使用する主なセレクタ:

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

互換目的で旧X 12.3系の以下も残している:

- `numberOfTabsV1In:`
- `numberOfTabsV2In:`
- `unifiedSegmentedController:...`

### 既知の挙動

`local_7.1.2_12.31.1.tipa` 実機確認時:

- 新規インストール/初期起動直後は「おすすめ」タブが表示された。
- 設定の「おすすめタブを非表示」を一度ON/OFF切り替えすると、非表示は正常に機能した。

つまりフックそのものは機能しているが、**初回ホーム構築時の設定反映/再読込タイミングに未解決の余地がある**。
今後修正する場合は、設定保存後ではなくホームタブDataSource初回構築時から確実に設定値が参照されるか確認すること。

ユーザーは現在の設定を一度切り替えて使用できている。

---

## 4. TrollStoreパッケージングで重要な修正

### 4.1 旧方式で発生した起動直後クラッシュ

最初は、本家配布済みTwitter TrollStore `.tipa` を展開し、新規ビルドした `BHTwitter.dylib` を単純差し替えしていた。
その結果、アプリがアイコンタップ直後にクラッシュした。

実ファイル比較で原因候補を特定:

本家配布版 `BHTwitter.dylib`:

```text
@rpath/CydiaSubstrate.framework/CydiaSubstrate
```

Theosで新規ビルドしたdylib:

```text
/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
```

本家TrollStore版では `CydiaSubstrate.framework` はアプリ内 `Frameworks` に存在するため、絶対パスのままではdyld段階で即終了し得る。

### 4.2 現在の正しい再梱包方法

`.github/workflows/package.yml` の `Assemble` で:

1. 本家Twitter TrollStore版 `.tipa` を展開。
2. 本家内の元 `BHTwitter.dylib` から:
   - CydiaSubstrate dependency
   - Mach-O install name
   を取得。
3. 新規ビルドdylibを差し替え。
4. `install_name_tool` で新規dylibの依存先を本家と同一に補正。
5. install nameも本家に合わせる。
6. `ldid -S` でdylibを署名。
7. 補正結果を `otool` で検証。
8. `BHTwitter.bundle` をNFB_Local版へ差し替え。
9. Info.plistから以下を削除:
   - `TSPreAppliedExploitType`
   - `TSBundlePreSigned`
10. 再ZIPして `.tipa` を生成。

run #3で確認済み:

```text
Base substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
Built substrate dependency: /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
Patched substrate dependency: @rpath/CydiaSubstrate.framework/CydiaSubstrate
```

この処理を削除したり、単純なdylib差し替えへ戻してはいけない。

---

## 5. Package Workflow

主要Workflow:

- `.github/workflows/package.yml`
- Actions表示名: `Package`
- 通常は `workflow_dispatch` の手動実行。

### ベースパッケージ選択

本家 `NeoFreeBird/app` のreleaseから以下の正規表現に一致するものだけを使用:

```regex
^NeoFreeBird-trollstore-Twitter_.*\.tipa$
```

つまり、**TwitterブランドのTrollStore版のみ**。

`base_tag` が空なら本家latest releaseを使用。
必要なら特定tagを指定可能。

### ビルド

- macOS GitHub hosted runner
- Theos
- iOS SDK default 16.5
- deployment target default 15.0
- ffmpeg buildをActions cacheで再利用

出力命名:

```text
local_<NFB_Local Version>_<Twitter App Version>.tipa
```

例:

```text
local_7.1.2_12.31.1.tipa
```

---

## 6. 本家更新時の追従手順

本家 `NeoFreeBird/app` に新しいrelease / source updateがあった場合、以下の順序で更新する。

### 6.1 まず差分確認

- 本家の新しい `v7` / releaseと、現在のNFB_Localを比較。
- 本家変更を丸ごと上書きしない。
- ローカル変更と競合するファイルを特定する。

特に確認するファイル:

- `src/Hooks/HomeBars.x`
- `src/Core/BHTSettings.m`
- `src/Settings/Pages/TimelinesSettingsViewController.m`
- `src/Hooks/FeatureSwitches.x`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings`
- `.github/workflows/package.yml`
- `control`

### 6.2 本家機能を取り込む

- 本家のバグ修正・新機能・設定変更をNFB_Localへ取り込む。
- ローカル独自変更を消さない。

### 6.3 日本語化更新

- English masterとJapaneseを比較。
- 新規キー/変更された英語を日本語化。
- `check_localization.py ja` / `--values` で確認。

### 6.4 「おすすめ」非表示を再適用

重要:

**古いセレクタを盲目的に再適用しない。**

新しいTwitter/X本体バージョンでホームタイムライン実装が変わっている可能性がある。
必要なら本家配布 `.tipa` 内のTwitter Mach-Oから:

- HomeTimelineContainer
- `numberOfTabs*`
- segmented controller data source
- `selectTimelineVariant*`
- Following / ForYou / latest

等のObjective-C method name / printable stringsを直接確認する。

そのバージョンに合わせて `hide_for_you_tab` 実装を調整する。

### 6.5 Package処理を維持

- TwitterブランドTrollStore版を基準にする。
- CydiaSubstrate dependencyの本家→新規dylibへのコピー補正を維持。
- `TSPreAppliedExploitType` / `TSBundlePreSigned` の削除を維持。

### 6.6 ビルド / 実機確認

最低限:

- Compile成功
- Assemble成功
- `@rpath/CydiaSubstrate.framework/CydiaSubstrate` へ補正済み
- ZIP integrity check成功
- Artifact upload成功

実機では:

- 起動できる
- Twitterブランド
- NeoFreeBird設定画面が日本語
- `「おすすめ」タブを非表示` が機能
- Followingが使用可能
- 固定/カスタムタイムラインを壊していない

を確認する。

---

## 7. 自動更新監視

ChatGPT側に **「NeoFreeBird追従更新」** という条件監視タスクを設定済み。

目的:

- 本家に意味のある更新があるか定期確認。
- 更新がなければ通知しない。
- 更新があればNFB_Localへの取り込み、日本語化、`hide_for_you_tab` 再適用、TrollStore package/buildまで進める。
- 安全に解決できない競合は、動作中の版を無理に壊さずユーザーへ通知する。

別チャットでこのタスクが見えない/利用できない場合でも、上記方針を手動で実施すればよい。

---

## 8. 過去に誤った判断 / 戻してはいけない点

### 「おすすめ」セレクタについて

途中でXNotForMeの現行実装を誤認し、12.31.1の実装を推測してセレクタを変更したことがある。
その後、12.31.1本体を直接解析して `numberOfTabsIn:` 系が存在することを確認した。

今後は外部tweakの対応バージョンと、実際に使用するTwitter/Xバージョンを必ず区別すること。

### 起動クラッシュについて

「TrollStoreの再署名だけが原因」と初期判断したが、それだけでは直らなかった。
最終的に新規dylibのCydiaSubstrate依存パス差異を確認し、`@rpath` 補正で起動するようになった。

よって、今後起動直後クラッシュが再発したら最初に:

```bash
otool -L BHTwitter.dylib
otool -D BHTwitter.dylib
```

で本家版と新規版を比較すること。

---

## 9. 現在の既知課題

1. `hide_for_you_tab` は実機で機能するが、初回起動時にはおすすめが表示され、一度設定をON/OFFした後に正常反映された。
   - 初回DataSource構築/設定反映タイミングの改善余地あり。

2. 本家更新でTwitter/Xの内部クラス・セレクタが変わる可能性がある。
   - 更新時に実バイナリを確認すること。

3. 現在 `hide_for_you_tab` defaultはOFF。
   - ユーザーから明示指示がない限り勝手にdefault ONへ変更しない。

---

## 10. 次チャット開始時の推奨プロンプト

次のチャットで作業を継続する場合は、以下のように指示すればよい。

> `oxUNKNOWNxo/NFB_Local` の `PROJECT_STATE.md` を最初に読み、その内容を基準に現在のmainを確認してから作業を続けてください。過去の単純dylib差し替え方式や古いHome Timelineセレクタへ戻さないでください。

---

## 11. 更新ルール

NFB_Localへ重要な修正を行った場合は、同じ作業内でこの `PROJECT_STATE.md` も更新すること。

特に必ず更新する項目:

- 本家NeoFreeBirdバージョン
- Twitter/Xアプリバージョン
- NFB_Localバージョン
- 最新成功Artifact / SHA-256
- `hide_for_you_tab` の互換実装
- Package方式に変更があった場合
- 新しい既知問題と解決済み問題

このファイルを古い状態のまま放置しないこと。
