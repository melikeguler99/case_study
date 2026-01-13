# NanoPipe (Nextflow) — NanoQC + NanoPlot for FASTQ

A small, reproducible Nextflow DSL2 pipeline to run **NanoQC** and **NanoPlot** on FASTQ files (e.g., Oxford Nanopore reads).

## Requirements
- Java (>= 11 recommended)
- Nextflow
- Conda (Miniconda/Anaconda) or Mamba (optional)

## Input
Put FASTQ/FASTQ.GZ files into:
- `data/`  (matched by `data/*.fastq*`)

## Run
```bash
./nextflow run chat.nf -with-conda
./nextflow run chat.nf -with-conda -resume
open data/results/*/nanoqc/*NanoQC*.html
open data/results/*/nanoplot/NanoPlot-report.html

Then add it:

```bash
git add README.md
