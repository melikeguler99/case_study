#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import argparse
import gzip
from pathlib import Path
from collections import namedtuple

import pandas as pd
from Bio import SeqIO

ReadInfo = namedtuple(
    "ReadInfo",
    ["SampleID", "ReadLength", "QualityScore", "GC"]
)

def gc_percent(seq: str) -> float:
    seq = seq.upper()
    bases = [b for b in seq if b in {"A", "C", "G", "T"}]
    if not bases:
        return float("nan")
    gc = sum(1 for b in bases if b in {"G", "C"})
    return 100 * gc / len(bases)

def mean_phred(record) -> float:
    quals = record.letter_annotations["phred_quality"]
    return sum(quals) / len(quals)

def get_sample_id(fastq_path: Path) -> str:
    name = fastq_path.name
    for suffix in [".fastq.gz", ".fq.gz", ".fastq", ".fq"]:
        if name.endswith(suffix):
            return name.replace(suffix, "")
    return fastq_path.stem

parser = argparse.ArgumentParser(
    description="Calculate read-level FASTQ statistics"
)
parser.add_argument(
    "--input", required=True, help="Input FASTQ or FASTQ.GZ file"
)
parser.add_argument(
    "--outdir", default=".", help="Output directory (default: current directory)"
)

args = parser.parse_args()

fastq_path = Path(args.input)
outdir = Path(args.outdir)
outdir.mkdir(parents=True, exist_ok=True)

sample_id = get_sample_id(fastq_path)
output_csv = outdir / f"{sample_id}_stats.csv"

reads = []

if fastq_path.suffix == ".gz":
    handle = gzip.open(fastq_path, "rt")
else:
    handle = open(fastq_path, "r")

with handle:
    for record in SeqIO.parse(handle, "fastq"):
        reads.append(
            ReadInfo(
                SampleID=sample_id,
                ReadLength=len(record.seq),
                QualityScore=mean_phred(record),
                GC=gc_percent(str(record.seq))
            )
        )

df = pd.DataFrame(reads)
df.to_csv(output_csv, index=False)

print(f"Saved: {output_csv}")

