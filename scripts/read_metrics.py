#!/usr/bin/env python3
"""
Read-level metrics 

Calculates for each read:
  - GC content percentage
  - Read length (bp)
  - Mean read quality score (Phred)

Outputs a structured CSV with columns:
  read_id,length_bp,mean_q,gc_percent
"""

import argparse
import gzip
from pathlib import Path

import pandas as pd
from Bio import SeqIO


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

    return pd.DataFrame(data, columns=["read_id", "length_bp", "mean_q", "gc_percent"])


def main():
    p = argparse.ArgumentParser(description="Compute per-read FASTQ QC metrics -> CSV")
    p.add_argument("--input", required=True, help="Input FASTQ/FASTQ.GZ")
    p.add_argument("--out_csv", required=True, help="Output CSV path")
    args = p.parse_args()

    fastq_file = Path(args.input)
    out_csv = Path(args.out_csv)

    df = parse_fastq(fastq_file)
    df.to_csv(out_csv, index=False)
    print(f"✔ Finished! Written: {out_csv}")


if __name__ == "__main__":
    main()
