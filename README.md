# 日本語 LaTeX テンプレート（GitHub Codespaces / Dev Container）

GitHub Codespaces または VS Code Dev Container 上で、**日本語のレポートや文書をすぐ書き始められる**
LaTeX 執筆環境テンプレートです。

- ✅ ブラウザだけで日本語 LaTeX を執筆（LaTeX Workshop 自動インストール）
- ✅ **LuaLaTeX** で `main.tex`（図・数式・表・参考文献入り）を即コンパイル
- ✅ TeX Live を含む Dev Container イメージを GHCR に公開済みで、起動時に TeX Live のインストールが走らない
- ✅ Python3 + pip（`numpy` / `matplotlib` 同梱）

## 使い方

1. **「Use this template」** から新規リポジトリを作成。
2. **Code ▸ Codespaces ▸ Create codespace** で起動（ビルド済みイメージを pull する
   だけで、TeX Live のインストールは走りません。ローカルの VS Code なら **「Reopen in Container」**）。
3. `main.tex` を編集。**保存すると自動ビルド**され `out/main.pdf` が更新されます
   （手動なら `latexmk main.tex`）。

## Python

`numpy` / `matplotlib` は起動時に自動インストールされます。追加したいパッケージは
`requirements.txt` に書けば次回起動時に入ります。

初回セットアップ（パッケージのインストールと図生成）はエディタの起動を妨げないよう
**背景で実行**されます。進捗・エラーは `/tmp/postcreate.log` で確認できます
（`figures/sample.png` は同梱済みなので、完了前でも `main.tex` はコンパイルできます）。

```bash
python3 scripts/make_figure.py   # figures/sample.png を再生成
```

## テスト

主要 LaTeX パッケージの対応可否（LuaLaTeX / upLaTeX）は
配布イメージ上で CI 検証しています。詳細は [`tests/`](tests/) を参照。

## ライセンス

MIT License。詳細は [`LICENSE`](LICENSE) を参照してください。
