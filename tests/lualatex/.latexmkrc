# ショーケース用：LuaLaTeX（root の latexmkrc と同じ設定）
$lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$pdf_mode = 4;          # 4 = lualatex
$out_dir  = 'out';
$max_repeat = 5;
