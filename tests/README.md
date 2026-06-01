# パッケージ対応テスト

このテンプレートが対応を想定している主要 LaTeX パッケージを、**実際の配布イメージ
（`ghcr.io/<repo>:latest`）上で**コンパイルし、`LuaLaTeX` / `upLaTeX` それぞれでの
サポート可否を網羅的に確認するためのテスト一式です。

ローカル（例: MacTeX scheme-full / 旧 TeX Live）でテストすると配布イメージに無い
パッケージまで「成功」してしまうため、**判定は GitHub Actions 上の配布イメージ内でのみ**
行います。

## 構成

| ファイル | 役割 |
|---|---|
| `packages.list` | 検証対象パッケージと、各パッケージで試す簡単な機能スニペットの一覧 |
| `run-tests.sh` | 各パッケージを両エンジンで個別コンパイルし、結果を `REPORT.md` に出力 |
| `lualatex/showcase.tex` | 主要パッケージをまとめて使う LuaLaTeX 統合文書（PDF 生成確認用） |
| `uplatex/showcase.tex` | 同上の upLaTeX + dvipdfmx 版 |
| `societies/` | 国内学会クラス（IPSJ / JSAI / IEICE）の**ビルド確認用スモークテスト**。`fetch-classes.sh` でクラスを取得し、各 `sample.tex` が upLaTeX + dvipdfmx でコンパイルできるかだけを確認する（投稿テンプレートではない） |
| `REPORT.md` | **CI 生成物（Artifact）**: パッケージ × エンジンのサポート可否マトリクス＋国内学会クラスのビルド確認結果。リポジトリにはコミットせず、実行ごとに Artifact として生成する |

## 実行方法（GitHub Actions）

- `tests/**` または `.github/workflows/test-packages.yml` を変更して push すると自動実行されます。
- 手動実行は GitHub の Actions タブから **Test LaTeX packages** ワークフローを
  `Run workflow`（`workflow_dispatch`）で起動します。
- 実行後、Actions の成果物（Artifacts）`latex-package-test` から `REPORT.md` と
  ショーケース PDF をダウンロードできます。結果サマリは run の Summary 画面にも表示されます。

> **前提**: `Build devcontainer image`（`build-image.yml`）が完了し、
> `ghcr.io/<repo>:latest` が公開済みであること。未公開だと container の pull に失敗します。

## 対象パッケージを追加するには

`packages.list` に 1 行追加します（区切りは ` ::: `）:

```
engines ::: name ::: preamble ::: body ::: note
```

- `engines`: `lua` / `up` を空白区切りで（両対応なら `lua up`）
- `preamble`: `\documentclass` 直後に入れる行（`\usepackage` や設定。無ければ `-`）
- `body`: `document` 環境内で機能を試すスニペット（無ければ `-`）
- `note`: 備考（無ければ `-`）

## 国内学会クラスのビルド確認

`societies/{ipsj,jsai,ieice}/` は各学会クラスのビルド可否を確認するスモークテストです
（投稿テンプレートではありません）。`run-tests.sh` が `societies/fetch-classes.sh` で
クラス（`ipsj.cls` / `jsaiac.cls` / `ieicej.cls`）を公式配布元から取得し、各 `sample.tex` を
upLaTeX + dvipdfmx でコンパイルして PASS/FAIL を `REPORT.md` に記録します。

クラスは各学会の配布物のためリポジトリには同梱しません（`.gitignore` で除外）。配布 URL の変更や
取得失敗、ビルド失敗はいずれも REPORT に記録するだけで、**CI ジョブは失敗させません**（非致命）。
ローカルで試す場合は `bash tests/societies/fetch-classes.sh` 後に各ディレクトリで `latexmk sample.tex` を実行します。
