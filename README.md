# qcPipe for long reads

The long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. One such quality control tool, Nanoplot, is a popular method to generate high-quality plots that visualise long read quality and length. `Nanoplot` also provides a statistical summary document that outlines the key features of the dataset. Similarly, PycoQC is another tool designed specifically for Oxford Nanopore data that produces interactive and highly customisable quality control plots for long-read datasets. 
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
- Compatible with macOS and Linux

---

## 🧰 Requirements

### Software

To run NanoPipe, the following are required:

- **Java (JDK ≥ 11)**  
- **Nextflow**  
- **Conda** (Miniconda or Anaconda)  

> **Optional but recommended:**  
> **Mamba** can be used as a faster alternative to Conda for environment resolution.

### Version Check

```bash
java -version
nextflow -version
conda --version
```
---

###  Input Data

The pipeline processes single-end FASTQ files, including both uncompressed and gzip-compressed formats.

Supported file extensions:

`.fastq` and`.fastq.gz`

Input files must be placed in the directory specified by the parameter:

params.fastq_dir (default: data/)

By default, the pipeline searches for:
```bash
data/*.fastq*
```
---

### Sample Identification

Sample names are automatically inferred from file names by removing the FASTQ extension.
For example:

Input file	Sample name
```bash
barcode77.fastq.gz	barcode77
sample_A.fastq	sample_A
```
This allows the pipeline to scale seamlessly to multiple samples without manual configuration.

---

###  Running the Pipeline

The pipeline is executed locally using Nextflow.

## Standard Execution
```bash
./nextflow run chat.nf -with-conda
```

## Resume Execution

To reuse previously completed steps (recommended during development or re-analysis):

```bash
./nextflow run chat.nf -with-conda -resume
```

## First-Run Behavior

On the first run, Nextflow will create a Conda environment based on env.yml.
This may take several minutes depending on network speed and solver configuration.
The environment is cached and reused for subsequent runs.

---

###  Output Structure

All results are organized per sample, ensuring clarity and traceability.
```bash
data/results/<sample>/
├── nanoqc/
│   └── <sample>_NanoQC.html
└── nanoplot/
    ├── NanoPlot-report.html
    ├── *.png
    └── *.log
```

---

### Output Description

NanoQC report
An interactive HTML summary of read quality metrics.

NanoPlot report
A comprehensive visualization suite including read length distributions, quality vs length plots, and yield statistics.

PNG files
High-resolution static plots suitable for reports and presentations.

---

###  Viewing Results

On macOS systems, reports can be opened directly from the terminal:
```bash
open data/results/*/nanoqc/*NanoQC*.html
open data/results/*/nanoplot/NanoPlot-report.html
```

Users on other operating systems may open the HTML files in any modern web browser.

###  Configuration and Customization

Default parameters are defined in nextflow.config:
```bash
params {
  fastq_dir = "$projectDir/data"
  out_dir   = "$projectDir/data/results"
}

```
Users may override these parameters at runtime:
```bash
./nextflow run chat.nf -with-conda \
  --fastq_dir /path/to/fastq_files \
  --out_dir /path/to/output_directory
```

This design ensures portability across different projects and file systems.
---
