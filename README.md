# qcPipe for long reads

While FastQC and MultiQC are great for short-read quality control,the long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. To assess sequencing quality using tools optimized for long-read technologies, the pipeline incorporates `NanoQC` and `NanoPlot`. These tools generate summary statistics, read-length distributions, yield plots, and interactive HTML reports.In addition to this, custom Python scripts was developed to compute read-level quality metrics directly from  file formats such as fastq and fastqz and calculates key summary statistics (mean, standard deviation, median, minimum, and maximum) for GC content, read length, and mean read quality score. These statistics are printed to standard output and also rendered directly into the final visualization image.
Following execution, all output files produced by qcpipe are automatically renamed to include the sample identifier (`sample_id`) as a filename prefix. This post-processing step ensures traceability and prevents filename collisions when aggregating results across multiple samples.


qcPipe is a reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files.With qcpipe, users can easily assess whether their data is ready for analysis using advanced tools like nanplot/nanoqc and custom analytics by providing standard sequence file formats such as fastq and fastqz.

The pipeline runs:
- **NanoQC** – HTML-based quality summary for long reads
- **NanoPlot** – read length, quality, and yield visualizations
- **read_metrics.py** - compute read-level quality metrics 
- **visualize_metrics.py** - perform data visualization and statistical summarization

**Overview**
- Present QC for raw reads (nanoQC)
- Plot QC (nanoplot)
- Custom QC analysis for raw reads (summary statistics as csv file and histograms)

All dependencies are handled via **Conda**, making the pipeline portable and easy to reproduce on different machines.

## Pipeline Workflow

![NanoPipe pipeline workflow](https://github.com/melikeguler99/case_study/blob/main/Pipeline_workflow.jpg)

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
### User guide


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

###  Running the Pipeline

- First clone this repo
```bash
git clone https://github.com/melikeguler99/case_study.git
cd case_study
```
The important features are:

`qcpipe.nf` contains the main nextflow script that calls all the processes in the workflow.
`nextflow.config` contains default parameters to use in the pipeline.
`modules/` contains individual process files for each step in the workflow.
`config/` contains infrastructure-specific config files (currently only contains gadi.config)

- Creta your personal data folder

```bash
mkdir -p data

```

```bash
cp <data_path> data/
```

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
            ├── sample_id_custom_qc_histograms.png
            └── sample_id_read_metrics.csv
```
---
### Output Description
* **NanoQC report**  
  An interactive HTML summary of sequencing quality metrics.

* **NanoPlot report**  
  A comprehensive visualization suite including read length distributions, quality vs. length plots, and overall yield statistics.

* **CSV file**  
  Per-read metrics are computed and written to a CSV file, including:
  - **GC content (%)** — proportion of G and C bases relative to read length  
  - **Read length (bp)** — total number of bases per read  
  - **Mean read quality score** — average Phred score across bases  

  The CSV contains one row per read with the following columns:  
  `read_id`, `length_bp`, `mean_q`, `gc_percent`

* **PNG files**  
  Distribution plots are generated as histograms for each metric:
  - GC content distribution  
  - Read-length distribution (log-transformed to accommodate long-read variability)  
  - Mean read quality score distribution  

All plots and summary statistics were combined into a single PNG file per sample.

---

###  Viewing Results

On macOS systems, reports can be opened directly from the terminal:
```bash
open results
open results/*/nanoplot/*NanoPlot-report*.html
open results/*/nanoqc/*.html
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


