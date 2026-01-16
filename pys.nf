#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.data_dir  = params.data_dir  ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/results"

workflow {

    Channel
        .fromPath("${params.data_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName()
            name = name.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(name, f)
        }
        .set { fastq_ch }

    advancedQC(fastq_ch)
    customQC(fastq_ch)
}
process advancedQC {
    tag "${sample}"
    publishDir "${params.out_dir}/${sample}", mode: 'copy'
    conda 'qc_env.yml'

    input:
    tuple val(sample), path(fastq)

    output:
    tuple val(sample), path("${sample}")

    script:
    """
    mkdir -p ${sample}/nanoqc ${sample}/nanoplot

    python3 - << 'EOF'
from nanoQC.nanoQC import main as nanoqc_main
import sys
sys.argv = ["nanoQC", "-o", "${sample}/nanoqc", "${fastq}"]
nanoqc_main()
EOF

    NanoPlot --fastq ${fastq} -o ${sample}/nanoplot
    """
}

from nanoQC.nanoQC import main as nanoqc_main
import sys
sys.argv = ["nanoQC", "-o", "nanoqc", "${fastq}"]
nanoqc_main()
EOF

    NanoPlot --fastq ${fastq} -o nanoplot

    mv nanoqc nanoplot ./
    """
}
process customQC {
    tag "${sample}"
    publishDir "${params.out_dir}/${sample}", mode: 'copy'
    conda "qc_env.yml"

    input:
    tuple val(sample), path(fastq)

    output:
    tuple val(sample), path("${sample}_read_metrics.csv")

    script:
    """
    python3 - << 'EOF'
import gzip
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")  # headless backend for Nextflow
import matplotlib.pyplot as plt
from Bio import SeqIO

# --- functions from your original code ---
def calc_gc(seq):
    seq = seq.upper()
    g = seq.count("G")
    c = seq.count("C")
    return 100.0 * (g + c) / len(seq) if len(seq) > 0 else 0.0

def mean_quality(quals):
    return sum(quals) / len(quals) if len(quals) > 0 else 0.0

def parse_fastq(fastq_file):
    data = []
    is_gz = str(fastq_file).endswith('.gz')
    open_fn = gzip.open if is_gz else open
    with open_fn(fastq_file, "rt") as handle:
        for record in SeqIO.parse(handle, "fastq"):
            length = len(record.seq)
            gc = calc_gc(record.seq)
            mq = mean_quality(record.letter_annotations["phred_quality"])
            data.append([record.id, length, round(mq,3), round(gc,2)])
    return pd.DataFrame(data, columns=["read_id","length_bp","mean_q","gc_percent"])

# --- read data ---
df = parse_fastq("${fastq}")

# --- save csv ---
out = "${sample}_read_metrics.csv"
df.to_csv(out, index=False)
print(f"Wrote: {out}")

# --- summary print ---
summary = pd.DataFrame({
    "mean":[df.gc_percent.mean(), df.length_bp.mean(), df.mean_q.mean()],
    "std":[df.gc_percent.std(), df.length_bp.std(), df.mean_q.std()],
    "median":[df.gc_percent.median(), df.length_bp.median(), df.mean_q.median()],
    "min":[df.gc_percent.min(), df.length_bp.min(), df.mean_q.min()],
    "max":[df.gc_percent.max(), df.length_bp.max(), df.mean_q.max()],
}, index=["GC_percent","Length_bp","Mean_Q"])
print(summary.round(3))

# --- custom histograms ---
plt.figure(figsize=(15,4))

# GC
plt.subplot(1,3,1)
plt.hist(df.gc_percent, bins=60, color="#6C5CE7", alpha=0.8)
plt.xlabel("GC %")
plt.ylabel("Count")
plt.title("GC content distribution")

# Length (kb)
plt.subplot(1,3,2)
plt.hist(df.length_bp/1000, bins=80, color="#00B894", alpha=0.8)
plt.xlabel("Length (kb)")
plt.ylabel("Count")
plt.title("Read length (kb)")

# Quality
plt.subplot(1,3,3)
plt.hist(df.mean_q, bins=60, color="#E17055", alpha=0.8)
plt.xlabel("Mean Q")
plt.ylabel("Count")
plt.title("Mean read quality")

plt.tight_layout()
plt.savefig(f"${sample}_qc_plots.png", dpi=150)
print(f"Wrote: ${sample}_qc_plots.png")

EOF
    """
}
