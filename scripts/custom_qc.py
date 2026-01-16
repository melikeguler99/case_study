#!/usr/bin/env python3
import gzip
from pathlib import Path
import argparse

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from Bio import SeqIO

# -----------------------------
# CONFIG / COLORS
# -----------------------------
COLORS = {
    "gc": "#6C5CE7",   # purple
    "len": "#00B894",  # teal / green
    "q": "#E17055",    # soft orange
}

# -----------------------------
# FUNCTIONS
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
            length = len(record.seq)
            gc = calc_gc(record.seq)
            mq = mean_quality(record.letter_annotations["phred_quality"])
            data.append([record.id, length, round(mq, 3), round(gc, 2)])

    df = pd.DataFrame(
        data,
        columns=["read_id", "length_bp", "mean_q", "gc_percent"],
    )
    return df


def save_metrics(df: pd.DataFrame, out_csv: Path):
    df.to_csv(out_csv, index=False)
    print(f"✔ Finished! Written: {out_csv}")


def print_summary(df: pd.DataFrame):
    """Clean, compact DataFrame-style summary."""
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
    print("\n=== Summary statistics ===")
    print(summary.round(3))


def plot_distributions(
    df: pd.DataFrame,
    bins_gc: int = 60,
    bins_len: int = 80,
    bins_q: int = 60,
    clip_len: int | None = None,
    use_log_len: bool = True,
    plot_png: str = "custom_qc_histograms.png",
    dpi: int = 150,
):
    """
    Produces the same plots as before, but ALSO saves them to disk (plot_png).
    This is required for headless execution (e.g., Nextflow), where plt.show()
    will not display a GUI window.
    """
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

    fig, ax = plt.subplots(1, 3, figsize=(16, 4.5))

    # GC content
    ax[0].hist(
        d["gc_percent"],
        bins=bins_gc,
        color=COLORS["gc"],
        edgecolor="white",
        alpha=0.85,
    )
    ax[0].set_title("GC content (%)", color=COLORS["gc"])
    ax[0].set_xlabel("GC %")
    ax[0].set_ylabel("Count")

    # Read length
    ax[1].hist(
        x_len,
        bins=bins_len,
        color=COLORS["len"],
        edgecolor="white",
        alpha=0.85,
    )
    ax[1].set_title(title_len, color=COLORS["len"])
    ax[1].set_xlabel(xlab)
    ax[1].set_ylabel("Count")

    # Mean quality
    ax[2].hist(
        d["mean_q"],
        bins=bins_q,
        color=COLORS["q"],
        edgecolor="white",
        alpha=0.85,
    )
    ax[2].set_title("Mean read quality (Q)", color=COLORS["q"])
    ax[2].set_xlabel("Mean Q")
    ax[2].set_ylabel("Count")

    fig.suptitle(
        f"Distributions (n={len(d):,}) — length clipped at {clip_len:,} bp",
        y=1.03,
        fontsize=12,
    )

    plt.tight_layout()

    # NEW: save plot for Nextflow/headless runs
    plt.savefig(plot_png, dpi=dpi)
    print(f"✔ Plot saved: {plot_png}")

    # Keep this to preserve your original behavior in interactive runs
    plt.show()


# -----------------------------
# MAIN PIPELINE
# -----------------------------
def main():
    p = argparse.ArgumentParser(description="Custom FASTQ QC metrics + plots")
    p.add_argument("--input", required=True, help="Input FASTQ/FASTQ.GZ")
    p.add_argument("--out_csv", default="read_metrics.csv", help="Output CSV name/path")
    p.add_argument(
        "--plot_png",
        default="custom_qc_histograms.png",
        help="Output PNG for histogram figure (saved to disk)",
    )
    args = p.parse_args()

    fastq_file = Path(args.input)
    out_csv = Path(args.out_csv)

    df = parse_fastq(fastq_file)
    save_metrics(df, out_csv)
    print_summary(df)

    plot_distributions(df, plot_png=args.plot_png)


if __name__ == "__main__":
    main()
