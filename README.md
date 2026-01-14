# qcPipe for long reads

The long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. One such quality control tool, Nanoplot, is a popular method to generate high-quality plots that visualise long read quality and length. Nanoplot also provides a statistical summary document that outlines the key features of the dataset. Similarly, PycoQC is another tool designed specifically for Oxford Nanopore data that produces interactive and highly customisable quality control plots for long-read datasets. 
To trim and filter long reads, Nanofilt (or its updated counterpart, Chopper) are helpful tools that can be run straight from the command line. 

qcPipe is a reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files, particularly suited for **Oxford Nanopore sequencing data**.

The pipeline runs:
- **NanoQC** – HTML-based quality summary for long reads
- **NanoPlot** – read length, quality, and yield visualizations

All dependencies are handled via **Conda**, making the pipeline portable and easy to reproduce on different machines.

---

##  Features

- Fully reproducible workflow using **Nextflow + Conda**
- Automatic sample detection from FASTQ filenames
- Per-sample output organization
- Works with `.fastq` and `.fastq.gz`
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
