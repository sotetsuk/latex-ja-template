# 学会テンプレ用：upLaTeX + dvipdfmx
$latex     = 'uplatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$bibtex    = 'upbibtex %O %S';
$dvipdf    = 'dvipdfmx %O -o %D %S';
$makeindex = 'mendex %O -o %D %S';
$pdf_mode  = 3;   # 3 = dvi -> pdf (dvipdfmx)
$out_dir   = 'out';
$max_repeat = 5;
