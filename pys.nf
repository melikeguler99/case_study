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

    input:
    tuple val(sample), path(fastq)

    output:
    tuple val(sample), path("${params.out_dir}/${sample}")

    script:
    """
    mkdir -p nanoqc nanoplot

    python3 - << 'EOF'
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
import matplotlib.pyplot as plt
from Bio import SeqIO

# --- exact same functions ---
def calc_gc(seq: str) -> float:
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

def save_metrics(df, out_csv):
    df.to_csv(out_csv, index=False)

def print_summary(df):
    summary = pd.DataFrame({
        "mean":[df.gc_percent.mean(), df.length_bp.mean(), df.mean_q.mean()],
        "std":[df.gc_percent.std(), df.length_bp.std(), df.mean_q.std()],
        "median":[df.gc_percent.median(), df.length_bp.median(), df.mean_q.median()],
        "min":[df.gc_percent.min(), df.length_bp.min(), df.mean_q.min()],
        "max":[df.gc_percent.max(), df.length_bp.max(), df.mean_q.max()],
    }, index=["GC_percent","Length_bp","Mean_Q"])
    print(summary.round(3))

df = parse_fastq("${fastq}")
out = "${sample}_read_metrics.csv"
save_metrics(df, out)
print_summary(df)
EOF
    """
}
