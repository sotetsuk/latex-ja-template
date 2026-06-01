#!/usr/bin/env bash
#
# 主要国内学会の LaTeX クラス／スタイルファイルを公式配布元から取得し、
# templates/<society>/ 配下に展開する。
#
# これらのファイルは各学会の配布物であり、本リポジトリには同梱していない
# （.gitignore で除外）。投稿規程は各学会の公式サイトで必ず確認すること。
#
# 使い方:
#   bash scripts/fetch-templates.sh            # 全学会
#   bash scripts/fetch-templates.sh ipsj jsai  # 指定した学会のみ
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="${ROOT}/templates"

# 公式ページ（配布 URL は更新されることがあるため、取得失敗時に案内する）
IPSJ_PAGE="https://www.ipsj.or.jp/journal/submit/style.html"
JSAI_PAGE="https://www.ai-gakkai.or.jp/published_books/transactions_of_jsai/toukou/journals_download/"
IEICE_PAGE="https://www.ieice.org/jpn_r/aboutus/rules/style.html"

# 既知の配布アーカイブ（変更され得る。失敗したら上記ページを参照）
IPSJ_ZIP="https://www.ipsj.or.jp/journal/submit/style/ipsj-template.zip"
JSAI_ZIP="https://www.ai-gakkai.or.jp/jsai/wp-content/uploads/sites/3/journals_download/jsaiac_tex_ja_utf8lf.zip"
IEICE_ZIP="https://www.ieice.org/ftp/tex/tech_rep/ieicej.zip"

have() { command -v "$1" >/dev/null 2>&1; }
if ! have unzip; then
  echo "[!] unzip が必要です（apt-get install -y unzip / sudo apt-get install unzip）" >&2
fi

fetch_one() {
  local name="$1" url="$2" page="$3"
  local dir="${TPL}/${name}"
  local tmp; tmp="$(mktemp -d)"
  echo "==> ${name}: ${url}"
  if curl -fSL --retry 2 -o "${tmp}/pkg.zip" "${url}" 2>/dev/null; then
    if unzip -oq "${tmp}/pkg.zip" -d "${dir}" 2>/dev/null; then
      echo "    OK -> ${dir}"
    else
      echo "    [!] 解凍に失敗しました。zip を ${dir} に手動展開してください。"
    fi
  else
    echo "    [!] 自動取得に失敗しました（URL が変更された可能性）。"
    echo "        公式ページから手動でダウンロードし、${dir}/ に展開してください:"
    echo "        ${page}"
  fi
  rm -rf "${tmp}"
}

declare -A URLS=( [ipsj]="${IPSJ_ZIP}" [jsai]="${JSAI_ZIP}" [ieice]="${IEICE_ZIP}" )
declare -A PAGES=( [ipsj]="${IPSJ_PAGE}" [jsai]="${JSAI_PAGE}" [ieice]="${IEICE_PAGE}" )

targets=("$@")
if [ "${#targets[@]}" -eq 0 ]; then
  targets=(ipsj jsai ieice)
fi

for t in "${targets[@]}"; do
  if [ -z "${URLS[$t]:-}" ]; then
    echo "[!] 不明な学会: ${t}（ipsj / jsai / ieice のいずれか）" >&2
    continue
  fi
  fetch_one "$t" "${URLS[$t]}" "${PAGES[$t]}"
done

echo
echo "取得後、各 templates/<society>/ で 'latexmk sample.tex' を実行してください。"
echo "（クラス名やファイル名は配布版に合わせて sample.tex を調整する必要がある場合があります）"
