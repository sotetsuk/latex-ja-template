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
  # 失敗理由を log から抽出
  local r
  r="$(grep -m1 -E '\.tex:[0-9]+: ' "$log" 2>/dev/null | sed -E 's/^[^:]*\.tex:[0-9]+: //')"
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
build_showcase() { # $1=subdir
  local sub="$1" pdf="$HERE/$1/out/showcase.pdf"
  ( cd "$HERE/$sub" && latexmk showcase.tex ) > "$WORK/showcase-$sub.log" 2>&1
  if [ -f "$pdf" ]; then echo "PASS"; else echo "FAIL"; SHOWCASE_FAIL=1; fi
}
SHOW_LUA="$(build_showcase lualatex)"
SHOW_UP="$(build_showcase uplatex)"

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
  echo "pygmentize  : $ENV_PYGMENTS   # minted に必要"
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
  echo "- \`pgf\`/\`tikz\`/\`pgfplots\` が ❌ の場合、配布プロファイルに \`collection-pictures\` が無いためです。"
  echo "  必要なら \`.devcontainer/texlive.profile\` に \`collection-pictures\` を追加してイメージを再ビルドしてください。"
  echo "  （\`tcolorbox\` は内部で pgf を使うため連動して失敗します。）"
  echo "- \`minted\` は Pygments と \`-shell-escape\` が前提です。代替として \`listings\` を推奨します。"
  echo "- \`biblatex\` はパッケージ読込のみ検証しています。実際の文献処理には biber（上表の環境を参照）が必要です。"
} > "$REPORT"

# ---- GitHub Actions のサマリにも出力 -------------------------------------
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$REPORT" >> "$GITHUB_STEP_SUMMARY"
fi

echo
echo "=== 完了 ==="
echo "パッケージ: LuaLaTeX ${pass_lua} PASS / ${fail_lua} FAIL,  upLaTeX ${pass_up} PASS / ${fail_up} FAIL"
echo "ショーケース: LuaLaTeX ${SHOW_LUA}, upLaTeX ${SHOW_UP}"
echo "レポート: $REPORT"

# ショーケースが失敗したらジョブを失敗扱いにする（個別パッケージの FAIL では落とさない）
exit "$SHOWCASE_FAIL"
