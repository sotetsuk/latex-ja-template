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
| `REPORT.md` | **生成物**: パッケージ × エンジンのサポート可否マトリクス |

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
