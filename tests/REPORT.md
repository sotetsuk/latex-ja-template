# 対応 LaTeX パッケージ 調査レポート

> このファイルは `tests/run-tests.sh` が GitHub Actions（配布イメージ `ghcr.io/sotetsuk/latex-ja-template:latest` の container）上で自動生成します。
> 判定はすべて**配布イメージ上での実コンパイル結果**です（ローカル環境ではなく）。

## サマリ

| 項目 | LuaLaTeX | upLaTeX |
|---|---|---|
| パッケージ PASS | 46 | 44 |
| パッケージ FAIL | 0 | 0 |
| 統合ショーケース | PASS | PASS |

## 環境

```
lualatex : This is LuaHBTeX, Version 1.24.0 (TeX Live 2026)
uplatex  : e-upTeX 3.141592653-p4.1.2-u2.02-251130-2.6 (utf8.uptex) (TeX Live 2026)
dvipdfmx : This is dvipdfmx Version 20260317 by the DVIPDFMx project team,
tlmgr    : tlmgr revision 78301 (2026-03-07 18:41:28 +0100)
biber       : あり (/usr/local/bin/biber)
bibtex      : あり (/usr/local/bin/bibtex)
upbibtex    : あり (/usr/local/bin/upbibtex)
pygmentize  : **なし**   # 旧 minted v2 用
latexminted : あり (/usr/local/bin/latexminted)   # minted v3 用（TeX Live 同梱）
```

<details><summary>インストール済み scheme / collection</summary>

```
- collection-basic: Essential programs and files
- collection-bibtexextra: BibTeX additional styles
- collection-binextra: TeX auxiliary programs
- collection-fontsrecommended: Recommended fonts
- collection-langcjk: Chinese/Japanese/Korean (base)
- collection-langjapanese: Japanese
- collection-latex: LaTeX fundamental packages
- collection-latexextra: LaTeX additional packages
- collection-latexrecommended: LaTeX recommended packages
- collection-mathscience: Mathematics, natural sciences, computer science packages
- collection-pictures: Graphics, pictures, diagrams
- scheme-basic: basic scheme (plain and latex)
- scheme-infraonly: infrastructure-only scheme (no TeX at all)
- scheme-minimal: minimal scheme (plain only)
```

</details>

## パッケージ別サポート状況

✅ = コンパイル成功 / ❌ = 失敗（理由を併記）/ — = そのエンジンでは対象外

| パッケージ | LuaLaTeX | upLaTeX | 備考 |
|---|:---:|:---:|---|
| `amsmath` | ✅ | ✅ |  |
| `amssymb` | ✅ | ✅ |  |
| `amsfonts` | ✅ | ✅ |  |
| `amsthm` | ✅ | ✅ |  |
| `mathtools` | ✅ | ✅ |  |
| `bm` | ✅ | ✅ | 太字数式 |
| `graphicx` | ✅ | ✅ |  |
| `xcolor` | ✅ | ✅ |  |
| `wrapfig` | ✅ | ✅ |  |
| `float` | ✅ | ✅ |  |
| `booktabs` | ✅ | ✅ |  |
| `array` | ✅ | ✅ | 列指定の拡張 |
| `multirow` | ✅ | ✅ |  |
| `longtable` | ✅ | ✅ | ページをまたぐ表 |
| `tabularx` | ✅ | ✅ |  |
| `makecell` | ✅ | ✅ | セル内改行 |
| `multicol` | ✅ | ✅ |  |
| `geometry` | ✅ | ✅ |  |
| `setspace` | ✅ | ✅ |  |
| `fancyhdr` | ✅ | ✅ |  |
| `titlesec` | ✅ | ✅ | 見出しの書式変更 |
| `enumitem` | ✅ | ✅ |  |
| `caption` | ✅ | ✅ |  |
| `subcaption` | ✅ | ✅ |  |
| `hyperref` | ✅ | ✅ |  |
| `url` | ✅ | ✅ |  |
| `cleveref` | ✅ | ✅ |  |
| `listings` | ✅ | ✅ |  |
| `fancyvrb` | ✅ | ✅ |  |
| `minted` | ✅ | ✅ | minted v3 (latexminted) で既定動作。Pygments 手動導入や --shell-escape は不要 |
| `ulem` | ✅ | ✅ |  |
| `csquotes` | ✅ | ✅ |  |
| `microtype` | ✅ | ✅ | upLaTeX→dvipdfmx では機能制限あり |
| `siunitx` | ✅ | ✅ | siunitx v3 想定 |
| `algorithm2e` | ✅ | ✅ |  |
| `algpseudocode` | ✅ | ✅ | algorithmicx |
| `tcolorbox` | ✅ | ✅ | 内部で pgf を読み込む |
| `pgf` | ✅ | ✅ | collection-pictures |
| `tikz` | ✅ | ✅ | collection-pictures |
| `pgfplots` | ✅ | ✅ | collection-pictures |
| `natbib` | ✅ | ✅ | 未定義引用は警告のみ |
| `biblatex` | ✅ | ✅ | biber の有無は環境チェックで確認 |
| `luatexja` | ✅ | — | jlreq が暗黙に読み込むが明示的に確認 |
| `fontspec` | ✅ | — | LuaLaTeX/XeLaTeX 専用 |
| `luatexja-fontspec` | ✅ | — |  |
| `unicode-math` | ✅ | — | OpenType 数式フォントが必要 |
| `otf` | — | ✅ | japanese-otf（丸囲み数字など） |
| `plext` | — | ✅ |  |

## 未対応・要追加設定（❌ の一覧）

（なし：対象パッケージはすべてコンパイルに成功しました）

### 補足
- `tikz`/`pgf`/`pgfplots`/`tcolorbox` は配布イメージに `collection-pictures` が含まれているため利用できます。
- `minted` は TeX Live 同梱の minted v3（`latexminted` + 制限付き shell-escape）により既定で動作します。
  旧来の `pygmentize`（Pygments）の手動導入や `-shell-escape` の明示指定は不要です。
- `biblatex` はパッケージ読込のみ検証しています。実際の文献処理には biber（上表の環境を参照。配布イメージには同梱）が必要です。
- `microtype` は LuaLaTeX では字形保護・伸縮が機能しますが、upLaTeX→dvipdfmx では機能が制限されます。
