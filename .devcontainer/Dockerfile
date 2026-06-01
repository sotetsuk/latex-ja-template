# syntax=docker/dockerfile:1
#
# 日本語 LaTeX 執筆用 Dev Container
# - ベース: debian:bookworm-slim（軽量）
# - TeX Live: install-tl + texlive.profile（バランス型）
# - Python3 + pip（numpy 等を後から追加可能）
#
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# ---- OS パッケージ ----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        curl \
        git \
        ca-certificates \
        perl \
        fontconfig \
        gnupg \
        xzdec \
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

# install-tl が作成したバイナリディレクトリを PATH に通す（年非依存）。
RUN set -eux; \
    TLBIN="$(echo /usr/local/texlive/*/bin/*)"; \
    echo "export PATH=${TLBIN}:\$PATH" > /etc/profile.d/texlive.sh; \
    ln -s "${TLBIN}"/* /usr/local/bin/ || true
ENV PATH=/usr/local/texlive/2025/bin/x86_64-linux:/usr/local/texlive/2024/bin/x86_64-linux:$PATH

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
