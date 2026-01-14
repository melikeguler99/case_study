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
- Compatible with macOS and Linux

---

## 🧰 Requirements

### Software

To run NanoPipe, the following are required:

- **Java (JDK ≥ 11)**  
  Required by Nextflow.
- **Nextflow**  
  Workflow execution engine.
- **Conda** (Miniconda or Anaconda)  
  Used to manage tool dependencies.

> **Optional but recommended:**  
> **Mamba** can be used as a faster alternative to Conda for environment resolution.

### Version Check

```bash
java -version
nextflow -version
conda --version
---
📥 Input Data

The pipeline processes single-end FASTQ files, including both uncompressed and gzip-compressed formats.

Supported file extensions:

.fastq

.fastq.gz

Input files must be placed in the directory specified by the parameter:

params.fastq_dir (default: data/)


By default, the pipeline searches for:

data/*.fastq*

Sample Identification

Sample names are automatically inferred from file names by removing the FASTQ extension.
For example:

Input file	Sample name
barcode77.fastq.gz	barcode77
sample_A.fastq	sample_A

This allows the pipeline to scale seamlessly to multiple samples without manual configuration.

🚀 Running the Pipeline

The pipeline is executed locally using Nextflow.

Standard Execution
./nextflow run chat.nf -with-conda

Resume Execution

To reuse previously completed steps (recommended during development or re-analysis):

./nextflow run chat.nf -with-conda -resume

First-Run Behavior

On the first run, Nextflow will create a Conda environment based on env.yml.
This may take several minutes depending on network speed and solver configuration.
The environment is cached and reused for subsequent runs.

📤 Output Structure

All results are organized per sample, ensuring clarity and traceability.

data/results/<sample>/
├── nanoqc/
│   └── <sample>_NanoQC.html
└── nanoplot/
    ├── NanoPlot-report.html
    ├── *.png
    └── *.log

Output Description

NanoQC report
An interactive HTML summary of read quality metrics.

NanoPlot report
A comprehensive visualization suite including read length distributions, quality vs length plots, and yield statistics.

PNG files
High-resolution static plots suitable for reports and presentations.

🌐 Viewing Results

On macOS systems, reports can be opened directly from the terminal:

open data/results/*/nanoqc/*NanoQC*.html
open data/results/*/nanoplot/NanoPlot-report.html


Users on other operating systems may open the HTML files in any modern web browser.

⚙️ Configuration and Customization

Default parameters are defined in nextflow.config:

params {
  fastq_dir = "$projectDir/data"
  out_dir   = "$projectDir/data/results"
}


Users may override these parameters at runtime:

./nextflow run chat.nf -with-conda \
  --fastq_dir /path/to/fastq_files \
  --out_dir /path/to/output_directory


This design ensures portability across different projects and file systems.

🔁 Reproducibility and Portability

This pipeline adheres to modern reproducible research practices:

Tool dependencies are explicitly defined in env.yml

Nextflow guarantees deterministic task execution

No absolute or machine-specific paths are used

The -resume option enables exact reuse of prior computations

As a result, the same inputs will produce consistent outputs across different systems.

🧪 Intended Use

This pipeline is intended for:

Educational case studies in bioinformatics and data science

Introductory quality control workflows for Oxford Nanopore sequencing data

Small- to medium-scale sequencing experiments

Teaching reproducible workflow design using Nextflow and Conda

Preliminary data exploration prior to downstream analysis

It is not intended to replace large-scale production QC pipelines, but rather to serve as a clear, reproducible, and extensible foundation.
## 📂 Project Structure

```text
.
├── chat.nf             # Main Nextflow pipeline (DSL2)
├── nextflow.config     # Default parameters and conda configuration
├── env.yml             # Conda environment definition
├── README.md           # Documentation
├── .gitignore
└── data/               # (not tracked) input FASTQ files
