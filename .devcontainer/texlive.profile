# TeX Live インストールプロファイル（バランス型・軽量）
# scheme-basic をベースに、日本語執筆と主要国内学会テンプレ
# （LuaLaTeX-ja / upLaTeX+dvipdfmx）に必要なコレクションだけを追加する。
# ドキュメント・ソースは含めずイメージを小さく保つ（約1.5GB目安）。

selected_scheme scheme-basic

# 追加コレクション
collection-latexrecommended 1
collection-latexextra 1
collection-fontsrecommended 1
collection-mathscience 1
collection-langjapanese 1
collection-bibtexextra 1
collection-binextra 1

# サイズ削減
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_autobackup 0
