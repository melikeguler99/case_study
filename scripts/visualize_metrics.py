#!/usr/bin/env python3
"""
Visualization 
  - prints summary statistics (mean/std/median/min/max)
  - generates distribution plots for GC%, read length, mean Q
  - saves a single PNG 
"""

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import pandas as pd

# -----------------------------
# CONFIG / COLORS
# -----------------------------
COLORS = {
    "gc": "#6C5CE7",
    "len": "#00B894",
    "q": "#E17055",
}


def build_summary(df: pd.DataFrame) -> pd.DataFrame:
    summary = pd.DataFrame(
        {
            "mean": [
                df["gc_percent"].mean(),
                df["length_bp"].mean(),
                df["mean_q"].mean(),
            ],
            "std": [
                df["gc_percent"].std(),
                df["length_bp"].std(),
                df["mean_q"].std(),
            ],
            "median": [
                df["gc_percent"].median(),
                df["length_bp"].median(),
                df["mean_q"].median(),
            ],
            "min": [
                df["gc_percent"].min(),
                df["length_bp"].min(),
                df["mean_q"].min(),
            ],
            "max": [
                df["gc_percent"].max(),
                df["length_bp"].max(),
                df["mean_q"].max(),
            ],
        },
        index=["GC_percent", "Length_bp", "Mean_Q"],
    )
    return summary


def print_summary(df: pd.DataFrame):
    summary = build_summary(df)
    print("\n=== Summary statistics ===")
    print(summary.round(3))


def plot_from_csv(
    df: pd.DataFrame,
    plot_png: Path,
    bins_gc=60,
    bins_len=80,
    bins_q=60,
    clip_len=None,
    use_log_len=True,
    dpi=150,
):
    d = df.copy()

    # Validate required columns
    required = {"gc_percent", "length_bp", "mean_q"}
    missing = required - set(d.columns)
    if missing:
        raise ValueError(f"Missing columns in CSV: {sorted(missing)}. Found: {list(d.columns)}")

    # Ensure numeric
    for col in ["gc_percent", "length_bp", "mean_q"]:
        d[col] = pd.to_numeric(d[col], errors="coerce")

    d = d.dropna(subset=["gc_percent", "length_bp", "mean_q"])
    if len(d) == 0:
        raise ValueError("No valid rows after numeric conversion / NaN removal.")

    if clip_len is None:
        clip_len = int(np.percentile(d["length_bp"], 99))
    d["length_clipped"] = d["length_bp"].clip(upper=clip_len)

    if use_log_len:
        x_len = np.log10(d["length_clipped"].clip(lower=1))
        xlab = "log10(Read length bp)"
        title_len = "Read length (log10)"
    else:
        x_len = d["length_clipped"]
        xlab = "Read length (bp)"
        title_len = "Read length (linear)"

    summary = build_summary(d).round(3)

    fig = plt.figure(figsize=(16, 6.3), dpi=dpi)
    gs = gridspec.GridSpec(
        nrows=2,
        ncols=3,
        height_ratios=[1.15, 4.0],
        hspace=0.35,
        wspace=0.25,
    )

    ax_top = fig.add_subplot(gs[0, :])
    ax_top.axis("off")

    ax_top.text(
        0.0,
        1.0,
        "=== Summary statistics ===\n" + summary.to_string(),
        va="top",
        ha="left",
        family="monospace",
        fontsize=11,
        transform=ax_top.transAxes,
    )

    ax0 = fig.add_subplot(gs[1, 0])
    ax1 = fig.add_subplot(gs[1, 1])
    ax2 = fig.add_subplot(gs[1, 2])

    # GC histogram
    ax0.hist(d["gc_percent"], bins=bins_gc, color=COLORS["gc"], edgecolor="white", alpha=0.85)
    ax0.set_title("GC content (%)", color=COLORS["gc"])
    ax0.set_xlabel("GC %")
    ax0.set_ylabel("Count")

    # Length histogram
    ax1.hist(x_len, bins=bins_len, color=COLORS["len"], edgecolor="white", alpha=0.85)
    ax1.set_title(title_len, color=COLORS["len"])
    ax1.set_xlabel(xlab)
    ax1.set_ylabel("Count")

    # Mean Q histogram
    ax2.hist(d["mean_q"], bins=bins_q, color=COLORS["q"], edgecolor="white", alpha=0.85)
    ax2.set_title("Mean read quality (Q)", color=COLORS["q"])
    ax2.set_xlabel("Mean Q")
    ax2.set_ylabel("Count")

    fig.suptitle(
        f"Distributions (n={len(d):,}) — length clipped at {clip_len:,} bp",
        y=0.98,
        fontsize=12,
    )

    plt.savefig(plot_png, dpi=dpi, bbox_inches="tight")
    print(f"✔ Plot saved: {plot_png}")
    plt.show()


def main():
    p = argparse.ArgumentParser(description="Visualize read-metrics CSV -> PNG + summary stats")
    p.add_argument("--input_csv", required=True, help="CSV produced by Part 1")
    p.add_argument("--plot_png", required=True, help="Output PNG path")
    args = p.parse_args()

    df = pd.read_csv(args.input_csv)
    print_summary(df)
    plot_from_csv(df, plot_png=Path(args.plot_png))


if __name__ == "__main__":
    main()

