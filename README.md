# qcPipe for long reads

While FastQC and MultiQC are great for short-read quality control,In case of long reads, we can check sequence quality with Nanoplot (De Coster et al. 2018). It provides basic statistics with nice plots for a fast quality control overview.
The long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. One such quality control tool, `Nanoplot`, is a popular method to generate high-quality plots that visualise long read quality and length. Nanoplot also provides a statistical summary document that outlines the key features of the dataset.

qcPipe is a reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files, particularly suited for **Oxford Nanopore sequencing data**.

With qcpipe, users can easily assess whether their data is ready for analysis using advanced tools like nanplot/nanoqc and custom analytics by providing standard sequence file formats such as fastq and fastqz.

The pipeline runs:
- **NanoQC** – HTML-based quality summary for long reads
- **NanoPlot** – read length, quality, and yield visualizations
- --custom apipe

- Present QC for raw reads (nanoQC)
- Plot QC (nanoplot)
- Custom QC analysis for raw reads (summary statistics as csv file and histograms)

All dependencies are handled via **Conda**, making the pipeline portable and easy to reproduce on different machines.

## Pipeline Workflow

![NanoPipe pipeline workflow](https://raw.githubusercontent.com/melikeguler99/case_study/main/workflows/qcpipe.png)

---

##  Features

- Fully reproducible workflow using **Nextflow + Conda**
- Automatic sample detection from FASTQ filenames
- Per-sample output organization
- Works with `.fastq` and `.fastq.gz`
- Compatible with macOS and Linux

---

## Requirements

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

- First clone this repo
```bash
git clone https://github.com/melikeguler99/case_study.git
cd case_study
```

- Creta your personal data folder

```bash
mkdir -p data

```

```bash
cp <data_path> data/
```

The pipeline is executed locally using Nextflow.

## Standard Execution
```bash
nextflow run qcpipe.nf -with-conda
```

## Resume Execution

To reuse previously completed steps (recommended during development or re-analysis):

```bash
nextflow run qcpipe.nf -with-conda -resume
```

## First-Run Behavior

On the first run, Nextflow will create a Conda environment based on env.yml.
This may take several minutes depending on network speed and solver configuration.
The environment is cached and reused for subsequent runs.

---

###  Output Structure

All results are organized per sample, ensuring clarity and traceability.
```bash
data/
 └── results/
      └── sample_id/
            ├── nanoplot/
            └── nanoqc/
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
params.fastq_dir = 'data/'
params.out_dir = 'results/'

```
Users may override these parameters at runtime:
```bash
nextflow run qcpipe.nf -with-conda \
  --fastq_dir <data_path> \
  --out_dir <results_folder>

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
  --input path/to/sample_id.fastq.gz \
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
  --input results/sample_id_stats.csv \
  --outdir figures
```
Output:
```bash
figures/sample_id_histograms.png
```
----
