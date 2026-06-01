# TeX Live インストールプロファイル（軽量）
# scheme-basic と日本語コレクションを土台にし、主要パッケージは
# texlive-packages.txt で明示的に追加する。
# ドキュメント・ソースは含めずイメージを小さく保つ。

selected_scheme scheme-basic

# 日本語執筆と主要国内学会テンプレの土台。
collection-langjapanese 1

# サイズ削減
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_autobackup 0
