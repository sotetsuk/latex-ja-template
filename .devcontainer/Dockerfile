# syntax=docker/dockerfile:1
#
# 日本語 LaTeX 執筆用 Dev Container
# - ベース: debian:bookworm-slim（軽量）
# - TeX Live: install-tl + texlive.profile（scheme-infraonly + 必要パッケージのみ・最小）
# - Python3 + pip（numpy 等を後から追加可能）
#
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# ---- OS パッケージ ----------------------------------------------------------
# wget/xzdec: install-tl と tlmgr のダウンロードに必要
# curl/unzip: 学会クラスの取得・展開（tests/societies）に必要
# perl: latexmk / TeX Live スクリプト, fontconfig: フォント解決
# python3*: minted v3 (latexminted) と図生成 (numpy/matplotlib)
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        curl \
        git \
        ca-certificates \
        perl \
        fontconfig \
        xzdec \
        unzip \
        python3 \
        python3-pip \
        python3-venv \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# ---- TeX Live（install-tl + プロファイル）----------------------------------
# 年ディレクトリ（例 2024/2025）はインストーラが決めるためハードコードしない。
# texlive-packages.txt は次の RUN（tlmgr install）まで残すのでここでは消さない。
COPY texlive.profile texlive-packages.txt /tmp/
RUN set -eux; \
    mkdir -p /tmp/install-tl; \
    wget -qO /tmp/install-tl.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz; \
    tar -xzf /tmp/install-tl.tar.gz -C /tmp/install-tl --strip-components=1; \
    /tmp/install-tl/install-tl --profile=/tmp/texlive.profile --no-interaction; \
    rm -rf /tmp/install-tl /tmp/install-tl.tar.gz /tmp/texlive.profile

# ---- 必要パッケージのみを明示インストール ----------------------------------
# scheme-infraonly には latex 本体すら入らないため、日本語執筆・CI テスト
# (tests/packages.list) ・学会スモークテストに必要なトップレベルパッケージを
# texlive-packages.txt から読み取って入れる。依存（kpathsea / l3kernel /
# hyphenation / 各種 .sty 等）は tlmgr が自動解決する。広いコレクションを
# 丸ごと入れないことでイメージを縮小する。
# tlmgr/fmtutil/kanji-config 等は install-tl が作ったバイナリ dir を PATH に
# 入れて呼ぶ（年ディレクトリ非依存）。バイナリの symlink はこの install 後に行う。
RUN set -eux; \
    export PATH="$(echo /usr/local/texlive/*/bin/*):$PATH"; \
    `# texlive-packages.txt から # 始まり行・空行を除いて tlmgr install へ渡す` \
    grep -Ev '^[[:space:]]*(#|$)' /tmp/texlive-packages.txt | xargs tlmgr install; \
    `# フォーマット（lualatex/uplatex 等）は tlmgr install が自動生成するが、` \
    `# 念のため全生成しておく（周辺フォーマットの失敗ではビルドを止めない）。` \
    fmtutil-sys --all || true; \
    `# upLaTeX+dvipdfmx 用に日本語フォント（原ノ味）をマップへ設定する` \
    kanji-config-updmap-sys haranoaji; \
    mktexlsr; \
    rm -f /tmp/texlive-packages.txt

# install-tl + tlmgr が入れた全バイナリ（lualatex/uplatex/biber/latexminted 等）を
# 年ディレクトリ非依存で PATH に通す。tlmgr install の「後」に行うことで、
# あとから入ったバイナリも確実に symlink される。
RUN set -eux; \
    TLBIN="$(echo /usr/local/texlive/*/bin/*)"; \
    echo "export PATH=${TLBIN}:\$PATH" > /etc/profile.d/texlive.sh; \
    ln -sf "${TLBIN}"/* /usr/local/bin/
ENV PATH=/usr/local/bin:$PATH

# ---- 非 root ユーザー（Codespaces / VSCode 互換）---------------------------
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /workspaces
