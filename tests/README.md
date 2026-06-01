# パッケージ対応テスト

主要 LaTeX パッケージが**配布イメージ（`ghcr.io/<repo>:latest`）上で** LuaLaTeX / upLaTeX
それぞれで使えるかを検証するテスト一式です。ローカルの全部入り環境では配布イメージに無い
パッケージまで「成功」してしまうため、判定は GitHub Actions 上の配布イメージ内でのみ行います。

## 構成

| ファイル | 役割 |
|---|---|
| `packages.list` | 検証対象パッケージと機能スニペットの一覧 |
| `run-tests.sh` | 各パッケージを両エンジンでコンパイルし `REPORT.md` を出力 |
| `lualatex/showcase.tex` / `uplatex/showcase.tex` | 主要パッケージの統合文書（PDF 生成確認） |
| `REPORT.md` | CI 生成物（Artifact）。リポジトリにはコミットしない |

## 実行（GitHub Actions）

`tests/**` を変更して push すると自動実行、または Actions タブの **Test LaTeX packages** を
手動実行します。結果は Artifact `latex-package-test` の `REPORT.md` とショーケース PDF で確認できます。

## パッケージを追加するには

`packages.list` に 1 行追加します（区切りは ` ::: `、無い項目は `-`）:

```
engines ::: name ::: preamble ::: body ::: note
```

`engines` は `lua` / `up` を空白区切り（両対応なら `lua up`）。
