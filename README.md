# qcPipe for long reads

While FastQC and MultiQC are great for short-read quality control,the long reads generated from platforms such as Oxford Nanopore Technologies can be analysed with specific packages that can handle the long and variable nature of these reads. One such quality control tool, `Nanoplot`(De Coster et al. 2018), is a popular method to generate high-quality plots that visualise long read quality and length. Nanoplot also provides a statistical summary document that outlines the key features of the dataset.

To assess sequencing quality using tools optimized for long-read technologies, the pipeline incorporates `NanoQC` and `NanoPlot`. These tools generate summary statistics, read-length distributions, yield plots, and interactive HTML reports.

Following execution, all output files produced by NanoQC and NanoPlot are automatically renamed to include the sample identifier (`sample_id`) as a filename prefix. This post-processing step ensures traceability and prevents filename collisions when aggregating results across multiple samples.

### Custom QC Analysis for long reads 

A custom Python script (read_metrics.py) was developed to compute read-level quality metrics directly from the FASTQ file. Using the Biopython library, each read was parsed and the following metrics were calculated:

- GC content (%), computed as the proportion of guanine and cytosine bases relative to read length

- Read length (bp), defined as the total number of bases per read

- Mean read quality score, calculated as the average Phred quality score across all bases in a read

The results were stored in a CSV file containing one row per read and the columns `read_id`, `length_bp`, `mean_q`, and `gc_percent`

The visualization script calculates key summary statistics (mean, standard deviation, median, minimum, and maximum) for GC content, read length, and mean read quality score. These statistics are printed to standard output and also rendered directly into the final visualization image.

Distribution plots were generated for each metric using histograms:

- GC content distribution

- Read-length distribution (log-transformed to account for long-read length variability)

- Mean read quality score distribution

All plots and summary statistics were combined into a single PNG file per sample. 

qcPipe is a reproducible **Nextflow (DSL2)** pipeline designed to perform **basic quality control and visualization** of FASTQ files, particularly suited for **Oxford Nanopore sequencing data**.With qcpipe, users can easily assess whether their data is ready for analysis using advanced tools like nanplot/nanoqc and custom analytics by providing standard sequence file formats such as fastq and fastqz.

The pipeline runs:
- **NanoQC** – HTML-based quality summary for long reads
- **NanoPlot** – read length, quality, and yield visualizations
- --custom apipe

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


