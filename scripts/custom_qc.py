#!/usr/bin/env python3
import argparse
import gzip
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import pandas as pd
from Bio import SeqIO

# -----------------------------
# CONFIG / COLORS
# -----------------------------
COLORS = {
    "gc": "#6C5CE7",
    "len": "#00B894",
    "q": "#E17055",
}

# -----------------------------
# METRICS
# -----------------------------
def calc_gc(seq: str) -> float:
    seq = str(seq).upper()
    g = seq.count("G")
    c = seq.count("C")
    return 100.0 * (g + c) / len(seq) if len(seq) > 0 else 0.0


def mean_quality(quals: list[int]) -> float:
    return sum(quals) / len(quals) if len(quals) > 0 else 0.0


def parse_fastq(fastq_file: Path) -> pd.DataFrame:
    data = []
    is_gz = fastq_file.suffix == ".gz"
    open_fn = gzip.open if is_gz else open

    with open_fn(fastq_file, "rt") as handle:
        for record in SeqIO.parse(handle, "fastq"):
            data.append(
                [
                    record.id,
                    len(record.seq),
                    round(mean_quality(record.letter_annotations["phred_quality"]), 3),
                    round(calc_gc(record.seq), 2),
                ]
            )

    return pd.DataFrame(
        data, columns=["read_id", "length_bp", "mean_q", "gc_percent"]
    )


# -----------------------------
# SUMMARY
# -----------------------------
def build_summary(df: pd.DataFrame) -> pd.DataFrame:
    return pd.DataFrame(
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


def print_summary(df: pd.DataFrame):
    summary = build_summary(df)
    print("\n=== Summary statistics ===")
    print(summary.round(3))


# -----------------------------
# PLOTTING
# -----------------------------
def plot_distributions(
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
    gs = gridspec.GridSpec(2, 3, height_ratios=[1.15, 4.0])

    ax_top = fig.add_subplot(gs[0, :])
    ax_top.axis("off")
    ax_top.text(
        0,
        1,
        "=== Summary statistics ===\n" + summary.to_string(),
        family="monospace",
        fontsize=11,
        va="top",
    )

    ax0 = fig.add_subplot(gs[1, 0])
    ax1 = fig.add_subplot(gs[1, 1])
    ax2 = fig.add_subplot(gs[1, 2])

    ax0.hist(d["gc_percent"], bins=bins_gc, color=COLORS["gc"], alpha=0.85)
    ax0.set_title("GC content (%)", color=COLORS["gc"])
    ax0.set_xlabel("GC %")
    ax0.set_ylabel("Count")

    ax1.hist(x_len, bins=bins_len, color=COLORS["len"], alpha=0.85)
    ax1.set_title(title_len, color=COLORS["len"])
    ax1.set_xlabel(xlab)
    ax1.set_ylabel("Count")

    ax2.hist(d["mean_q"], bins=bins_q, color=COLORS["q"], alpha=0.85)
    ax2.set_title("Mean read quality (Q)", color=COLORS["q"])
    ax2.set_xlabel("Mean Q")
    ax2.set_ylabel("Count")

    fig.suptitle(
        f"Distributions (n={len(d):,}) — length clipped at {clip_len:,} bp",
        y=0.98,
    )

    plt.savefig(plot_png, bbox_inches="tight")
    print(f"✔ Plot saved: {plot_png}")
    plt.show()


# -----------------------------
# MAIN
# -----------------------------
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--out_csv", required=True)
    p.add_argument("--plot_png", required=True)
    args = p.parse_args()

    df = parse_fastq(Path(args.input))
    df.to_csv(args.out_csv, index=False)
    print(f"✔ Finished! Written: {args.out_csv}")

    print_summary(df)
    plot_distributions(df, plot_png=Path(args.plot_png))


if __name__ == "__main__":
    main()
