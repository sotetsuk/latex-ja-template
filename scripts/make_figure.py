#!/usr/bin/env python3
"""figures/sample.png を生成するサンプルスクリプト。

numpy で正弦波を計算し matplotlib で描画する。
Python3 + pip（numpy / matplotlib）の動作確認も兼ねている。

使い方:
    python3 scripts/make_figure.py
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # GUI 不要のバックエンド
import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).resolve().parent.parent / "figures" / "sample.png"


def main() -> None:
    x = np.linspace(0, 2 * np.pi, 400)
    y1 = np.sin(x)
    y2 = np.sin(x) * np.exp(-x / 6)

    fig, ax = plt.subplots(figsize=(6, 3.5), dpi=150)
    ax.plot(x, y1, label=r"$\sin(x)$")
    ax.plot(x, y2, label=r"$\sin(x)\,e^{-x/6}$")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_title("Sample figure (numpy + matplotlib)")
    ax.legend()
    ax.grid(True, alpha=0.3)
    fig.tight_layout()

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
