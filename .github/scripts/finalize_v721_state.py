from pathlib import Path
import re

p = Path("PROJECT_STATE.md")
s = p.read_text(encoding="utf-8")
s = s.replace("最終更新: 2026-10-16 (JST)", "最終更新: 2026-10-17 (JST)", 1)

sec2 = """## 2. 現在の基準バージョン

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

---"""
s = re.sub(r"## 2\. 現在の基準バージョン\n.*?\n---", sec2, s, count=1, flags=re.S)

sec3 = """## 3. 2026-10-17 本家v7.2.0同期内容

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

---"""
s = re.sub(r"## 3\. 2026-10-15 本家v7同期内容\n.*?\n---", sec3, s, count=1, flags=re.S)

s = s.replace(
    "7.1.6同期時:\n\n- 英語 / 日本語の設定キー構成: **303 / 303**\n- 新規キーを日本語化済み。\n- 英語原文が変更された `REPLY_SORTING_DETAIL` も内容に合わせて更新済み。",
    "7.2.1同期時:\n\n- 日本語Localizable: **307 / 307 (100%)**\n- v7.2.0新規キーを日本語化済み。\n- 既存英語原文の変更も確認して追従済み。",
)
s = s.replace("この項目はLocalizable.stringsの303件には含まれない。", "この項目はLocalizable.stringsの307件には含まれない。")
s = s.replace("Twitter 12.31.1での概念上のindex:", "Twitter 12.33でも実バイナリ再確認済みの概念上のindex:")
s = s.replace("12.31.1で実バイナリ確認済みの主なselector:", "12.33で実バイナリ再確認済みの主なselector:")
s = s.replace(
    "公式releaseのTwitter/Xアプリ版が12.31.1から変わった場合は、Home Timeline内部APIを実バイナリで再確認すること。",
    "公式releaseのTwitter/Xアプリ版が12.33から変わった場合も、`Inspect upstream Twitter binary` を使ってHome Timeline内部APIを実バイナリで再確認すること。",
)
s = s.replace("この7.1.5由来の実装は7.1.6でも保持されている。", "この7.1.5由来の実装は7.2.1でも保持されている。")

sec10 = """## 10. 本家更新時の自動追従手順

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

---"""
s = re.sub(r"## 10\. 本家更新時の自動追従手順\n.*?\n---", sec10, s, count=1, flags=re.S)

s = s.replace("## 12. 7.1.6 要実機確認", "## 12. 7.2.1 要実機確認")
s = s.replace(
    "3. 新規設定（リンク追跡、既定リプライ並べ替え、引用/リツイート非表示）が表示される。",
    "3. v7.2.0の刷新された設定画面、新規設定、投稿元ラベル等が正常に表示される。",
)
s = s.replace(
    "公式Twitterアプリ版が12.31.1から変わった場合は、Home Timeline selectorを推測せず実バイナリで再確認してください。",
    "公式Twitterアプリ版が12.33から変わった場合は、ChatGPT環境のダウンロード可否に依存せず `Inspect upstream Twitter binary` をGitHub Actionsで実行し、Home Timeline selectorを推測せず実バイナリで再確認してください。",
)

needle = "したがって、2026-10-16時点で **ready branch → Package → Promote verified update → main fast-forward の経路は実走確認済み**。"
addition = needle + """

2026-10-17のv7.2.1更新でも実運用経路を再確認済み:

- Package run: `38989163366` 成功
- ready SHA: `f40f49a7c325d087d7637485131ecd29b5a560a6`
- Promote run: `38989437820` 成功
- `3d408370...` → `f40f49a...` をforceなしでfast-forward
"""
if needle in s and "Promote run: `38989437820`" not in s:
    s = s.replace(needle, addition, 1)

p.write_text(s, encoding="utf-8")
