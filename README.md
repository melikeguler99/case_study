# qcPipe for long reads

The long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. One such quality control tool, Nanoplot, is a popular method to generate high-quality plots that visualise long read quality and length. `Nanoplot` also provides a statistical summary document that outlines the key features of the dataset. Similarly, PycoQC is another tool designed specifically for Oxford Nanopore data that produces interactive and highly customisable quality control plots for long-read datasets. 
To trim and filter long reads, Nanofilt (or its updated counterpart, Chopper) are helpful tools that can be run straight from the command line. 

qcPipe is a reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files, particularly suited for **Oxford Nanopore sequencing data**.

The pipeline runs:
- **NanoQC** – HTML-based quality summary for long reads
- **NanoPlot** – read length, quality, and yield visualizations

All dependencies are handled via **Conda**, making the pipeline portable and easy to reproduce on different machines.

## Pipeline Workflow

![NanoPipe pipeline workflow](https://raw.githubusercontent.com/melikeguler99/case_study/main/workflows/qcpipe.png)

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
./nextflow run qcpipe.nf -with-conda
```

## Resume Execution

To reuse previously completed steps (recommended during development or re-analysis):

```bash
./nextflow run qcpipe.nf -with-conda -resume
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

* NanoQC report:
An interactive HTML summary of read quality metrics.

* NanoPlot report:
A comprehensive visualization suite including read length distributions, quality vs length plots, and yield statistics.

* PNG files:
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

### Custom QC Analysis for long reads 

This repository includes two simple Python scripts for basic quality analysis of FASTQ files in the `case_study/custom_python_scripts/.`
They are designed for users who want a **transparent, script-based workflow** without relying on advanced QC tools.

# Pipeline Workflow 2

![NanoPipe pipeline workflow](https://raw.githubusercontent.com/melikeguler99/case_study/main/workflows/custom_py.png)

## Requirements for the Python Scripts

To run the custom FASTQ analysis scripts, the following are required:

- **Python 3.8 or newer**
- **Required Python libraries:**
  - `numpy`
  - `pandas`
  - `matplotlib`

These libraries are used for numerical calculations, data handling, and plotting.

---

### Optional (Recommended)

- **gzip support** (built into Python) for reading `.fastq.gz` files
- A UNIX-like environment (Linux or macOS) for easier command-line usage

---

### Check Installation

```bash
python --version
python -c "import numpy, pandas, matplotlib"
```
---

###  Read-Level Statistics

The first script (`custom_script.py`) processes a FASTQ file and calculates the following **for each individual read**:

- GC content percentage  
- Read length  
- Mean read quality score  

The results are saved in a structured format (CSV) for downstream analysis.

Run the script on a single FASTQ file:

```bash
python custom_script.py \
  --input path/to/sample.fastq.gz \
  --outdir results
```
The output file will be automatically named using the input filename (e.g.,barcode77.fastq.gz → barcode77_stats.csv) and saved in the specified output directory.

To process multiple FASTQ files in a directory:
```bash
for fq in fastqz/*.fastq.gz; do
  python custom_script.py --input "$fq" --outdir results
done
```
**Output example:**
- `SampleID`
- `ReadLength`
- `QualityScore`
- `GC`
---
###  Data Visualization

The second script (`custom_script_vis.py`) uses the output file from first python script and generates distribution plots. 

```bash
python custom_script_vis.py \
  --input results/sample_stats.csv \
  --outdir figures
```
Output:
```bash
figures/sample_histograms.png
```
----
