# 日本語 LaTeX テンプレート（GitHub Codespaces / Dev Container）

GitHub Codespaces または VS Code Dev Container 上で、**日本語論文をすぐ書き始められる**
LaTeX 執筆環境テンプレートです。

- ✅ ブラウザだけで日本語 LaTeX を執筆（GitHub Codespaces 対応）
- ✅ VS Code 拡張 **LaTeX Workshop** を自動インストール
- ✅ **LuaLaTeX** で `main.tex` を新規作成・コンパイル
- ✅ 人工知能学会・情報処理学会・電子情報通信学会の主要クラスの**ビルド可否を CI でスモークテスト**（投稿テンプレートとしては提供しません）
- ✅ 軽量な TeX Live 構成（`scheme-basic` + 必要コレクションのみ、約 1.5GB）
- ✅ Python3 + pip（`numpy` / `matplotlib` 同梱、追加も自由）
- ✅ 画像・数式・表・参考文献入りの `main.tex` で即執筆

## 使い方

### 1. このテンプレートから新規リポジトリを作成
GitHub 上で **「Use this template」**（このテンプレートを使用）から作成します。

### 2. Codespaces を起動
リポジトリの **Code ▸ Codespaces ▸ Create codespace** で起動します。
初回はコンテナをビルドするため数分かかります（→ 下記 **prebuild** で短縮可能）。

> ローカルの VS Code で使う場合は、Docker を入れて
> **「Reopen in Container」**（コンテナーで再度開く）を選びます。

### 3. 執筆・コンパイル
`main.tex` を開いて編集します。**保存すると自動でビルド**され、`out/main.pdf` が更新されます。
手動ビルドは次のとおり。

```bash
latexmk main.tex      # -> out/main.pdf（LuaLaTeX）
```

## 即起動の仕組み（ビルド済みイメージ）

このテンプレートは、TeX Live を含む Dev Container イメージを **GitHub Actions で
ビルドし GHCR に公開**しています（[`.github/workflows/build-image.yml`](.github/workflows/build-image.yml)）。
`devcontainer.json` はそのイメージ（`ghcr.io/<owner>/<repo>:latest`）を **pull するだけ**で、
起動時に TeX Live のインストールは走りません。テンプレートから作った各リポジトリも同様に高速です。

### このテンプレートを自分用にフォーク／流用する場合
1. `.devcontainer/devcontainer.json` の `image` を **自分のリポジトリ名**に書き換える
   （例: `ghcr.io/<あなた>/<リポジトリ>:latest`）。
2. main に push すると CI がイメージをビルドして GHCR に公開する。
3. **Settings ▸ Packages** で公開した GHCR パッケージの **可視性を Public** にする
   （初回のみ。Private のままだと codespace 起動時に pull できない）。
4. Dockerfile を変更したら push するだけで CI が再ビルド＆公開し、次回起動から反映される。

> さらに起動を詰めたい場合は **Settings ▸ Codespaces ▸ Set up prebuild**（任意）も併用できますが、
> 上記のビルド済みイメージだけでも十分高速です。

## Python の利用

`numpy` と `matplotlib` は起動時に自動インストールされます。

```bash
python3 scripts/make_figure.py          # figures/sample.png を再生成
pip3 install --break-system-packages scipy   # パッケージ追加例
```

追加したいパッケージは `requirements.txt` に書けば次回起動時に入ります。

## 対応パッケージとテスト

主要な LaTeX パッケージが**実際の配布イメージ上で**使えるかを、LuaLaTeX / upLaTeX の
両方でコンパイルして検証する CI を用意しています（[`tests/`](tests/)）。

- **最新のサポート可否マトリクス・ショーケース PDF**:
  [Test LaTeX packages ワークフロー](https://github.com/sotetsuk/latex-ja-template/actions/workflows/test-packages.yml)
  → 最新 run の **Summary**、または **Artifacts (`latex-package-test`)** の `REPORT.md` を参照。
- 検証内容や対象パッケージの追加方法は [`tests/README.md`](tests/README.md) を参照してください。

国内学会クラス（IPSJ / JSAI / IEICE）も、配布元から取得してコンパイルが通るかを CI で
スモークテストしています（`tests/societies/`）。**投稿テンプレートとしての提供ではなく**、
クラスがビルドできることの確認のみで、取得・ビルドの失敗は CI を落としません。

## ディレクトリ構成

```
.devcontainer/   # Dev Container 定義（Dockerfile / texlive.profile / devcontainer.json）
.vscode/         # LaTeX Workshop レシピ・推奨拡張
main.tex         # LuaLaTeX サンプル（図・数式・表・参考文献）
references.bib   # 参考文献データベース
latexmkrc        # ルート文書のビルド設定（LuaLaTeX）
requirements.txt # Python 依存（numpy, matplotlib）
scripts/         # make_figure.py（図生成）
figures/         # 画像（sample.png）
tests/           # 対応パッケージの網羅テスト（CI で実行・レポート生成）
tests/societies/ # 国内学会クラスのビルド確認テスト（ipsj / jsai / ieice）
```

## トラブルシュート

- **不足パッケージのエラー**: バランス型構成のため一部パッケージが未収録の場合があります。`sudo tlmgr install <パッケージ名>` で追加できます。
- **日本語が出ない / 文字化け**: ファイルを UTF-8 で保存し、`main.tex` は LuaLaTeX（既定レシピ）でビルドしてください。

## ライセンス

このテンプレート自体のファイルは自由に利用・改変できます。
各学会のクラスファイルおよび投稿規程は、それぞれの学会の規約に従ってください。
