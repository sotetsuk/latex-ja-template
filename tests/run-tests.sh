#!/usr/bin/env bash
# =============================================================
#  対応 LaTeX パッケージの網羅テスト
#  - tests/packages.list の各パッケージを LuaLaTeX / upLaTeX で個別にコンパイルし
#    PASS/FAIL（失敗理由付き）を tests/REPORT.md にマトリクスとして書き出す。
#  - tests/{lualatex,uplatex}/showcase.tex を latexmk で PDF までビルドして確認する。
#  実行は GitHub Actions 上（配布イメージ container 内）を想定。
#  個別パッケージの FAIL ではジョブを落とさない。ショーケースのビルド失敗のみ exit 1。
# =============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/packages.list"
REPORT="$HERE/REPORT.md"
WORK="$HERE/.work"
rm -rf "$WORK"; mkdir -p "$WORK/lua" "$WORK/up"

# ---- エンジン定義 ---------------------------------------------------------
# lua: LuaLaTeX + jlreq / up: upLaTeX + jsarticle(dvipdfmx)
class_for() {
  case "$1" in
    lua) printf '\\documentclass[lualatex,fontsize=10.5pt]{jlreq}' ;;
    up)  printf '\\documentclass[uplatex,dvipdfmx]{jsarticle}' ;;
  esac
}
cmd_for() {
  case "$1" in
    lua) echo "lualatex" ;;
    up)  echo "uplatex" ;;
  esac
}

# ---- 1パッケージを1エンジンでコンパイル ----------------------------------
# 戻り値: 0=PASS / 1=FAIL。理由は変数 LAST_REASON に格納。
LAST_REASON=""
compile_one() {
  local engine="$1" name="$2" pre="$3" body="$4"
  local dir="$WORK/$engine"
  local tex="$dir/${name}.tex"
  local log="$dir/${name}.log"
  [ "$pre" = "-" ] && pre=""
  [ "$body" = "-" ] && body=""
  # <NL> を実改行に変換（verbatim 系は \end{...} が行頭でないと runaway するため）
  local NL=$'\n'
  pre="${pre//<NL>/$NL}"
  body="${body//<NL>/$NL}"
  {
    class_for "$engine"; echo
    [ -n "$pre" ] && printf '%s\n' "$pre"
    echo '\begin{document}'
    printf '日本語テスト。%s\n' "$body"
    echo '\end{document}'
  } > "$tex"

  LAST_REASON=""
  ( cd "$dir" && "$(cmd_for "$engine")" \
      -interaction=nonstopmode -halt-on-error -file-line-error \
      -output-directory="$dir" "${name}.tex" ) > /dev/null 2>&1
  local rc=$?
  if [ $rc -eq 0 ]; then
    return 0
  fi
  # 失敗理由を log から抽出（Error 行を優先、次に file:line 形式、次に "! " 行）
  local r
  r="$(grep -m1 -E '(LaTeX|Package|Class|pdfTeX|LuaTeX)[^:]* Error' "$log" 2>/dev/null | sed -E 's/^.*Error: ?//; s/^.*Error//')"
  [ -z "$r" ] && r="$(grep -m1 -E '^(\./)?[^ ]*:[0-9]+: ' "$log" 2>/dev/null | sed -E 's#^(\./)?[^:]*:[0-9]+: ##')"
  [ -z "$r" ] && r="$(grep -m1 -E '^! ' "$log" 2>/dev/null | sed -E 's/^! //')"
  [ -z "$r" ] && r="$(grep -m1 -iE 'not found|cannot|fatal' "$log" 2>/dev/null)"
  [ -z "$r" ] && r="(原因不明: ${name}.log を参照)"
  LAST_REASON="$(echo "$r" | tr -d '\r' | cut -c1-110)"
  return 1
}

# ---- 環境情報 -------------------------------------------------------------
toolver() { command -v "$1" >/dev/null 2>&1 && { "$1" --version 2>&1 | head -1; } || echo "NOT FOUND"; }
present() { command -v "$1" >/dev/null 2>&1 && echo "あり ($(command -v "$1"))" || echo "**なし**"; }

echo ">>> 環境情報を収集中..."
ENV_LUALATEX="$(toolver lualatex)"
ENV_UPLATEX="$(toolver uplatex)"
ENV_DVIPDFMX="$(toolver dvipdfmx)"
ENV_TLMGR="$(toolver tlmgr)"
ENV_BIBER="$(present biber)"
ENV_BIBTEX="$(present bibtex)"
ENV_UPBIBTEX="$(present upbibtex)"
ENV_PYGMENTS="$(present pygmentize)"
ENV_LATEXMINTED="$(present latexminted)"
COLLECTIONS="$(tlmgr info --only-installed 2>/dev/null | grep -E '(collection|scheme)-' | sed -E 's/^i?\s*/- /' | sort -u || true)"
[ -z "$COLLECTIONS" ] && COLLECTIONS="(取得不可)"

# ---- パッケージ別マトリクス ----------------------------------------------
echo ">>> パッケージ別コンパイルを実行中..."
declare -a ORDER
declare -A R_LUA R_UP RE_LUA RE_UP HAS_LUA HAS_UP NOTE
pass_lua=0; fail_lua=0; pass_up=0; fail_up=0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  engines="${line%% ::: *}"; rest="${line#* ::: }"
  name="${rest%% ::: *}";   rest="${rest#* ::: }"
  pre="${rest%% ::: *}";    rest="${rest#* ::: }"
  body="${rest%% ::: *}";   note="${rest#* ::: }"
  ORDER+=("$name"); NOTE["$name"]="$note"
  if [[ " $engines " == *" lua "* ]]; then
    HAS_LUA["$name"]=1
    if compile_one lua "$name" "$pre" "$body"; then R_LUA["$name"]=PASS; ((pass_lua++)); else R_LUA["$name"]=FAIL; RE_LUA["$name"]="$LAST_REASON"; ((fail_lua++)); fi
    printf '  [lua] %-20s %s\n' "$name" "${R_LUA[$name]}"
  fi
  if [[ " $engines " == *" up "* ]]; then
    HAS_UP["$name"]=1
    if compile_one up "$name" "$pre" "$body"; then R_UP["$name"]=PASS; ((pass_up++)); else R_UP["$name"]=FAIL; RE_UP["$name"]="$LAST_REASON"; ((fail_up++)); fi
    printf '  [up ] %-20s %s\n' "$name" "${R_UP[$name]}"
  fi
done < "$LIST"

cell() { # $1=result $2=reason
  if [ "$1" = "PASS" ]; then echo "✅"
  elif [ "$1" = "FAIL" ]; then echo "❌ <sub>$2</sub>"
  else echo "—"; fi
}

# ---- 統合ショーケースのビルド --------------------------------------------
echo ">>> 統合ショーケースをビルド中..."
SHOWCASE_FAIL=0
build_showcase() { # $1=subdir  -> stdout: PASS/FAIL（診断は stderr へ。SHOWCASE_FAIL は呼び出し側で設定）
  local sub="$1" pdf="$HERE/$1/out/showcase.pdf" log="$WORK/showcase-$1.log"
  ( cd "$HERE/$sub" && latexmk showcase.tex ) > "$log" 2>&1
  if [ -f "$pdf" ]; then
    echo "PASS"
  else
    echo "FAIL"
    { echo "---- showcase ($sub) FAILED: tail of $(basename "$log") ----"; tail -40 "$log"; echo "----"; } >&2
  fi
}
# 注: $(...) はサブシェルのため、関数内で SHOWCASE_FAIL を立てても親に伝わらない。
#     戻り値（PASS/FAIL）を見て親シェルでフラグを立てる。
SHOW_LUA="$(build_showcase lualatex)"; [ "$SHOW_LUA" = FAIL ] && SHOWCASE_FAIL=1
SHOW_UP="$(build_showcase uplatex)";   [ "$SHOW_UP" = FAIL ] && SHOWCASE_FAIL=1

# ---- 国内学会クラスのビルド確認（非致命） --------------------------------
# 学会クラス（ipsj/jsaiac/ieicej）を公式配布元から取得し、各 sample.tex が upLaTeX +
# dvipdfmx でコンパイルできるかだけを確認する。投稿テンプレートではなくスモークテスト。
# 取得失敗・ビルド失敗とも REPORT に記録するが、ジョブの成否（exit code）には影響させない。
echo ">>> 国内学会クラスのビルド確認中..."
SOC_DIR="$HERE/societies"
SOC_ORDER=(ipsj jsai ieice)
declare -A SOC_LABEL=( [ipsj]="情報処理学会 (IPSJ)" [jsai]="人工知能学会 (JSAI)" [ieice]="電子情報通信学会 (IEICE)" )
declare -A SOC_CLS=( [ipsj]="ipsj.cls" [jsai]="jsaiac.cls" [ieice]="ieicej.cls" )
declare -A SOC_FETCH SOC_BUILD SOC_NOTE
soc_build_pass=0

if command -v unzip >/dev/null 2>&1; then
  SOC_HAS_UNZIP=1
  bash "$SOC_DIR/fetch-classes.sh" > "$WORK/fetch-classes.log" 2>&1 || true
else
  SOC_HAS_UNZIP=0
fi

build_society() { # $1=society $2=クラスファイル名。結果は SOC_* 連想配列に直接格納（サブシェル不使用）
  local soc="$1" cls="$2" dir="$SOC_DIR/$1" log="$WORK/society-$1.log"
  if [ "$SOC_HAS_UNZIP" != "1" ]; then
    SOC_FETCH["$soc"]="FAIL"; SOC_BUILD["$soc"]="—"; SOC_NOTE["$soc"]="unzip 不在のため取得・展開不可"
    return
  fi
  if [ ! -f "$dir/$cls" ]; then
    SOC_FETCH["$soc"]="FAIL"; SOC_BUILD["$soc"]="—"
    SOC_NOTE["$soc"]="$cls 未取得（配布 URL 変更等。fetch-classes.log を参照）"
    return
  fi
  SOC_FETCH["$soc"]="PASS"
  ( cd "$dir" && latexmk sample.tex ) > "$log" 2>&1
  if [ -f "$dir/out/sample.pdf" ]; then
    SOC_BUILD["$soc"]="PASS"; SOC_NOTE["$soc"]=""; ((soc_build_pass++))
  else
    SOC_BUILD["$soc"]="FAIL"
    local r
    r="$(grep -m1 -E '(LaTeX|Package|Class|pdfTeX|LuaTeX)[^:]* Error' "$log" 2>/dev/null | sed -E 's/^.*Error: ?//; s/^.*Error//')"
    [ -z "$r" ] && r="(ビルド失敗: society-$soc.log を参照)"
    SOC_NOTE["$soc"]="$(echo "$r" | tr -d '\r' | cut -c1-90)"
  fi
}
for s in "${SOC_ORDER[@]}"; do
  build_society "$s" "${SOC_CLS[$s]}"
  printf '  [soc] %-6s 取得:%-4s ビルド:%s\n' "$s" "${SOC_FETCH[$s]}" "${SOC_BUILD[$s]}"
done

soc_cell() { case "$1" in PASS) echo "✅";; FAIL) echo "❌";; *) echo "—";; esac; }

# ---- REPORT.md 生成 -------------------------------------------------------
echo ">>> REPORT.md を生成中..."
{
  echo "# 対応 LaTeX パッケージ 調査レポート"
  echo
  echo "> このファイルは \`tests/run-tests.sh\` が GitHub Actions（配布イメージ \`ghcr.io/${GITHUB_REPOSITORY:-OWNER/REPO}:latest\` の container）上で自動生成します。"
  echo "> 判定はすべて**配布イメージ上での実コンパイル結果**です（ローカル環境ではなく）。"
  echo
  echo "## サマリ"
  echo
  echo "| 項目 | LuaLaTeX | upLaTeX |"
  echo "|---|---|---|"
  echo "| パッケージ PASS | $pass_lua | $pass_up |"
  echo "| パッケージ FAIL | $fail_lua | $fail_up |"
  echo "| 統合ショーケース | $SHOW_LUA | $SHOW_UP |"
  echo "| 国内学会クラスのビルド | — | ${soc_build_pass}/${#SOC_ORDER[@]} PASS |"
  echo
  echo "## 環境"
  echo
  echo '```'
  echo "lualatex : $ENV_LUALATEX"
  echo "uplatex  : $ENV_UPLATEX"
  echo "dvipdfmx : $ENV_DVIPDFMX"
  echo "tlmgr    : $ENV_TLMGR"
  echo "biber       : $ENV_BIBER"
  echo "bibtex      : $ENV_BIBTEX"
  echo "upbibtex    : $ENV_UPBIBTEX"
  echo "pygmentize  : $ENV_PYGMENTS   # 旧 minted v2 用"
  echo "latexminted : $ENV_LATEXMINTED   # minted v3 用（TeX Live 同梱）"
  echo '```'
  echo
  echo "<details><summary>インストール済み scheme / collection</summary>"
  echo
  echo '```'
  echo "$COLLECTIONS"
  echo '```'
  echo
  echo "</details>"
  echo
  echo "## パッケージ別サポート状況"
  echo
  echo "✅ = コンパイル成功 / ❌ = 失敗（理由を併記）/ — = そのエンジンでは対象外"
  echo
  echo "| パッケージ | LuaLaTeX | upLaTeX | 備考 |"
  echo "|---|:---:|:---:|---|"
  for n in "${ORDER[@]}"; do
    cl_lua="—"; cl_up="—"
    [ "${HAS_LUA[$n]:-}" = "1" ] && cl_lua="$(cell "${R_LUA[$n]}" "${RE_LUA[$n]:-}")"
    [ "${HAS_UP[$n]:-}" = "1" ]  && cl_up="$(cell "${R_UP[$n]}" "${RE_UP[$n]:-}")"
    nt="${NOTE[$n]}"; [ "$nt" = "-" ] && nt=""
    echo "| \`$n\` | $cl_lua | $cl_up | $nt |"
  done
  echo
  echo "## 未対応・要追加設定（❌ の一覧）"
  echo
  found_fail=0
  for n in "${ORDER[@]}"; do
    if [ "${R_LUA[$n]:-}" = "FAIL" ]; then echo "- \`$n\` (LuaLaTeX): ${RE_LUA[$n]}"; found_fail=1; fi
    if [ "${R_UP[$n]:-}" = "FAIL" ];  then echo "- \`$n\` (upLaTeX): ${RE_UP[$n]}"; found_fail=1; fi
  done
  [ "$found_fail" = "0" ] && echo "（なし：対象パッケージはすべてコンパイルに成功しました）"
  echo
  echo "### 補足"
  echo "- \`tikz\`/\`pgf\`/\`pgfplots\`/\`tcolorbox\` は配布イメージに \`collection-pictures\` が含まれているため利用できます。"
  echo "- \`minted\` は TeX Live 同梱の minted v3（\`latexminted\` + 制限付き shell-escape）により既定で動作します。"
  echo "  旧来の \`pygmentize\`（Pygments）の手動導入や \`-shell-escape\` の明示指定は不要です。"
  echo "- \`biblatex\` はパッケージ読込のみ検証しています。実際の文献処理には biber（上表の環境を参照。配布イメージには同梱）が必要です。"
  echo "- \`microtype\` は LuaLaTeX では字形保護・伸縮が機能しますが、upLaTeX→dvipdfmx では機能が制限されます。"
  echo
  echo "## 国内学会クラスのビルド確認"
  echo
  echo "各学会のクラス（配布物のため未同梱）を \`tests/societies/fetch-classes.sh\` で取得し、"
  echo "\`tests/societies/<学会>/sample.tex\` を upLaTeX + dvipdfmx でコンパイルできるかだけを確認します。"
  echo "**これらは投稿テンプレートではなくビルドのスモークテストであり、取得・ビルドの失敗は CI を落としません。**"
  echo
  echo "✅ = 成功 / ❌ = 失敗（理由を併記）/ — = 前段失敗のため未実行"
  echo
  echo "| 学会 | クラス | 取得 | ビルド | 備考 |"
  echo "|---|---|:---:|:---:|---|"
  for s in "${SOC_ORDER[@]}"; do
    nt="${SOC_NOTE[$s]}"
    echo "| ${SOC_LABEL[$s]} | \`${SOC_CLS[$s]}\` | $(soc_cell "${SOC_FETCH[$s]}") | $(soc_cell "${SOC_BUILD[$s]}") | $nt |"
  done
} > "$REPORT"

# ---- GitHub Actions のサマリにも出力 -------------------------------------
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$REPORT" >> "$GITHUB_STEP_SUMMARY"
fi

echo
echo "=== 完了 ==="
echo "パッケージ: LuaLaTeX ${pass_lua} PASS / ${fail_lua} FAIL,  upLaTeX ${pass_up} PASS / ${fail_up} FAIL"
echo "ショーケース: LuaLaTeX ${SHOW_LUA}, upLaTeX ${SHOW_UP}"
echo "国内学会クラスのビルド: ${soc_build_pass}/${#SOC_ORDER[@]} PASS（非致命）"
echo "レポート: $REPORT"

# ショーケースが失敗したらジョブを失敗扱いにする（個別パッケージの FAIL では落とさない）
exit "$SHOWCASE_FAIL"
