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
COPY texlive.profile /tmp/texlive.profile
RUN set -eux; \
    mkdir -p /tmp/install-tl; \
    wget -qO /tmp/install-tl.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz; \
    tar -xzf /tmp/install-tl.tar.gz -C /tmp/install-tl --strip-components=1; \
    /tmp/install-tl/install-tl --profile=/tmp/texlive.profile --no-interaction; \
    rm -rf /tmp/install-tl /tmp/install-tl.tar.gz /tmp/texlive.profile

# ---- 必要パッケージのみを明示インストール ----------------------------------
# scheme-infraonly には latex 本体すら入らないため、日本語執筆・CI テスト
# (tests/packages.list) ・学会スモークテストに必要なトップレベルパッケージを
# 列挙して入れる。依存（kpathsea / l3kernel / hyphenation / 各種 .sty 等）は
# tlmgr が自動解決する。広いコレクションを丸ごと入れないことでイメージを縮小する。
# tlmgr/fmtutil/kanji-config 等は install-tl が作ったバイナリ dir を PATH に
# 入れて呼ぶ（年ディレクトリ非依存）。バイナリの symlink はこの install 後に行う。
RUN set -eux; \
    export PATH="$(echo /usr/local/texlive/*/bin/*):$PATH"; \
    tlmgr install \
        `# --- latex 本体・エンジン・ビルド基盤 ---` \
        latex latex-bin latexmk luatex \
        `# --- 日本語（upLaTeX/dvipdfmx 系・クラス）---` \
        platex uplatex ptex ptex-fontmaps jsclasses jlreq dvipdfmx \
        `# --- 日本語組版・フォント（otf は upTeX 用ファイルも japanese-otf に同梱）---` \
        luatexja japanese-otf haranoaji \
        `# --- フォント基盤（fontspec/unicode-math/microtype 用）---` \
        fontspec lm lm-math \
        `# --- 数式 ---` \
        amsmath amsfonts amscls mathtools unicode-math \
        `# --- 図・色・表・レイアウト（array/longtable/tabularx/multicol/bm は tools）---` \
        graphics tools xcolor wrapfig float booktabs multirow makecell \
        geometry setspace fancyhdr titlesec enumitem \
        `# --- キャプション・参照・コード ---` \
        caption hyperref url cleveref listings fancyvrb minted ulem \
        csquotes microtype \
        `# --- 単位・アルゴリズム・囲み ---` \
        siunitx algorithm2e algorithmicx algorithms tcolorbox \
        `# --- 描画（tikz は pgf に含まれる）---` \
        pgf pgfplots \
        `# --- 参考文献 ---` \
        natbib biblatex biber \
    ; \
    `# フォーマット（lualatex/uplatex 等）は tlmgr install が自動生成するが、` \
    `# 念のため全生成しておく（周辺フォーマットの失敗ではビルドを止めない）。` \
    fmtutil-sys --all || true; \
    `# upLaTeX+dvipdfmx 用に日本語フォント（原ノ味）をマップへ設定する` \
    kanji-config-updmap-sys haranoaji; \
    mktexlsr

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
