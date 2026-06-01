# ルート文書（main.tex）は LuaLaTeX で組版する。
$lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$pdf_mode = 4;          # 4 = lualatex
$out_dir  = 'out';
$bibtex   = 'bibtex';
$bibtex_use = 2;        # 必要なら bbl を自動生成
$max_repeat = 5;
