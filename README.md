# qcPipe for raw long-read data

`qcPipe` is a reproducible Nextflow DSL2 pipeline for basic quality control and visualization of long-read sequencing data. The workflow allows users to quickly assess whether `.fastq`and `.fastq.gz` is suitable for downstream analysis using both standardized QC tools and custom analytics.

While FastQC and MultiQC are great for short-read quality control,the long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. To address this, `qcPipe` integrates `NanoQC` and `NanoPlot`, providing long-read-aware summaries such as read-length distributions, yield plots, and interactive HTML reports.In addition to these tools, custom Python scripts compute per-read quality metrics and calculate key summary statistics (mean, median, standard deviation, minimum, and maximum) for GC content, read length, and mean read quality score. These statistics are printed to standard output and embedded directly into the final visualization image.

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

![NanoPipe pipeline workflow](https://github.com/melikeguler99/case_study/blob/main/Pipeline_workflow.png)

## Requirements

To run  qcpipe, the following are required:

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

# **User guide**

#  1. Input Data

The pipeline processes single-end FASTQ files, including both uncompressed and gzip-compressed formats.

Supported file extensions:

`.fastq` and `.fastq.gz`

Input files must be placed in the directory specified by the parameter:

```bash
params.fastq_dir (default: data/)
```

By default, the pipeline searches for:
```bash
data/*.{fastq,fastq.gz}
```

#  2. Running the Pipeline

## 2.1 Repository Setup

- 2.1.1. First clone this repo
```bash
git clone https://github.com/melikeguler99/case_study.git
cd case_study
```
> - The important features are:
> - `qcPipe.nf` – contains the main Nextflow script that calls all processes in the workflow.
> - `nextflow.config` – contains default parameters used by the pipeline.
> - `scripts/` – contains Python scripts called by the workflow processes.

- 2.1.2. Creta your personal data folder
```bash
mkdir -p data

```

```bash
cp <data_path> data/
```

## 2.2 Standard Execution
```bash
nextflow run qcPipe.nf -with-conda
```
On the first run, Nextflow will create a Conda environment based on env.yml.
This may take several minutes depending on network speed and solver configuration.
The environment is cached and reused for subsequent runs.

## 2.3 Resume Execution

To reuse previously completed steps (recommended during development or re-analysis):

```bash
nextflow run qcPipe.nf -with-conda -resume
```

# 3. Results 

## 3.1 Output Structure

Following execution, all output files produced by qcPipe are automatically renamed to include the sample identifier (`sample_id`) as a filename prefix. This post-processing step ensures traceability and prevents filename collisions when aggregating results across multiple samples.

```bash
results/
 └── sample_id/
      ├── nanoplot/
      │    ├── sample_id_NanoPlot-report.html
      │    ├── sample_id_NanoStats.txt
      │    └── sample_id_*.png / sample_id_*.html
      ├── nanoqc/
      │    └── sample_id_*.html
      ├── sample_id_read_metrics.csv
      └── sample_id_custom_qc_histograms.png

```
## 3.2 Output Description
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

# 4. Configuration and Customization

Default parameters are defined in nextflow.config:

```bash
params.fastq_dir = 'data/'
params.out_dir = 'results/'
```
Users may override these parameters at runtime:

```bash
nextflow run qcPipe.nf -with-conda \
  --fastq_dir <data_path> \
  --out_dir   <results_folder>

```
