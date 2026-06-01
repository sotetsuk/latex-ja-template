# TeX Live インストールプロファイル（最小・明示パッケージ方式）
# scheme-infraonly（tlmgr + 最小インフラのみ）をベースにし、日本語執筆と
# CI テスト（tests/packages.list）/ 主要国内学会テンプレ（LuaLaTeX-ja /
# upLaTeX+dvipdfmx）に必要な「個別パッケージ」だけを Dockerfile の
# `tlmgr install` で追加する。広いコレクションを丸ごと入れないことで、
# 数百の未使用パッケージを排除しイメージを大幅に小さく保つ。
#   （profile はスキーム/コレクション単位の選択用で、個別パッケージは
#    列挙できないため、パッケージ追加は Dockerfile 側で行う。）
# 実サイズは CI（build-image.yml）のビルドログで確認できる。

selected_scheme scheme-infraonly

# サイズ削減（ドキュメント・ソース・自動バックアップを含めない）
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_autobackup 0
