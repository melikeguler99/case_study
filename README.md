# NanoPipe – Nextflow Pipeline for NanoQC & NanoPlot

NanoPipe is a small, reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files, particularly suited for **Oxford Nanopore sequencing data**.

The pipeline runs:
- **NanoQC** – HTML-based quality summary
- **NanoPlot** – read length, quality, and yield visualizations

All dependencies are handled via **Conda**, making the pipeline portable and easy to reproduce on different machines.

---

## ✨ Features

- Fully reproducible workflow using **Nextflow + Conda**
- Automatic sample detection from FASTQ filenames
- Per-sample output organization
- Works with `.fastq` and `.fastq.gz`
- No hard-coded paths
- Suitable for local execution and teaching / case studies

---

## 📂 Project Structure

```text
.
├── chat.nf             # Main Nextflow pipeline (DSL2)
├── nextflow.config     # Default parameters and conda configuration
├── env.yml             # Conda environment definition
├── README.md           # Documentation
├── .gitignore
└── data/               # (not tracked) input FASTQ files
