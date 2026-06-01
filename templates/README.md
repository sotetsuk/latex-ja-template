# 国内学会テンプレート

人工知能学会（JSAI）・情報処理学会（IPSJ）・電子情報通信学会（IEICE）の
投稿用 LaTeX テンプレートです。

## 重要

これらの学会のクラス／スタイルファイル（`ipsj.cls`, `jsaiac.*`, `ieicej.cls` など）は
**各学会の配布物のため本リポジトリには含めていません**（`.gitignore` で除外）。
次のスクリプトで公式配布元から取得してください。

```bash
bash scripts/fetch-templates.sh            # 全学会まとめて取得
bash scripts/fetch-templates.sh ipsj       # 個別取得も可能
```

配布 URL が変わっている場合はスクリプトが公式ページを案内します。
手動でダウンロードした zip を該当 `templates/<society>/` に展開しても構いません。

## コンパイル

各学会テンプレは **upLaTeX + dvipdfmx** で組版します
（各ディレクトリの `.latexmkrc` に設定済み）。

```bash
cd templates/ipsj      # jsai / ieice も同様
latexmk sample.tex     # -> out/sample.pdf
```

VSCode では `sample.tex` を開き、LaTeX Workshop のレシピ
**「upLaTeX -> dvipdfmx (latexmk)」** を選んでビルドします。

## 注意

`sample.tex` は最小例です。クラス名・オプション・著者欄のマクロは
取得した配布版のドキュメント（同梱 PDF / readme）に合わせて調整してください。
最新の投稿規程は必ず各学会の公式サイトで確認してください。
