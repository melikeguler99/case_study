nextflow.enable.dsl=2

/*
 * updated_pipe.nf
 *
 * Inputs:
 *   params.fastq_dir = "<project>/data"
 * Outputs:
 *   params.out_dir   = "<project>/data/results"
 *
 * Runs:
 *   - NanoQC (HTML)
 *   - NanoPlot (directory of plots)
 *   - Custom per-read stats CSV (GC%, ReadLength, Mean Phred)
 *   - Visualization plots + summary stats from the CSV
 */

params.fastq_dir = "${projectDir}/data"
params.out_dir   = "${projectDir}/data/results"

workflow {

    // Find FASTQ/FASTQ.GZ files and create (fastq, sample_name) tuples
    Channel.fromPath("${params.fastq_dir}/*.fastq*")
        .map { file ->
            // Handles: sample.fastq, sample.fastq.gz
            def sample_name = file.getBaseName().replaceFirst(/\.fastq$/, '')
            tuple(file, sample_name)
        }
        .set { fastq_ch }

    // Existing QC tools
    processNanoQC(fastq_ch)
    processNanoPlot(fastq_ch)

    // Part 1: per-read metrics -> CSV
    read_stats_ch = processReadStats(fastq_ch)

    // Part 2: plots + summary stats from CSV
    processReadStatsViz(read_stats_ch)
}


/* -------------------------
 * NanoQC
 * ------------------------- */
process processNanoQC {
    tag "$sample_name"
    publishDir "${params.out_dir}/${sample_name}/nanoqc", mode: 'copy'

    input:
    tuple path(fastq), val(sample_name)

    output:
    path "${sample_name}_NanoQC.html"

    script:
    """
    nanoqc $fastq
    mv nanoQC.html ${sample_name}_NanoQC.html
    """
}


/* -------------------------
 * NanoPlot
 * ------------------------- */
process processNanoPlot {
    tag "$sample_name"
    publishDir "${params.out_dir}/${sample_name}/nanoplot", mode: 'copy'

    input:
    tuple path(fastq), val(sample_name)

    output:
    path "*"

    script:
    """
    NanoPlot --fastq $fastq -o .
    """
}


/* -------------------------
 * Part 1: Custom per-read stats -> CSV
 * Requires: python, pandas/numpy not needed for Part 1 script (stdlib ok)
 * Output: <sample>_read_stats.csv
 * ------------------------- */
process processReadStats {
    tag "$sample_name"
    publishDir "${params.out_dir}/${sample_name}/readstats", mode: 'copy'

    input:
    tuple path(fastq), val(sample_name)

    output:
    tuple val(sample_name), path("${sample_name}_read_stats.csv")

    script:
    """
    python ${projectDir}/scripts/fastq_read_stats.py \
      --input $fastq \
      --sample $sample_name \
      --out ${sample_name}_read_stats.csv
    """
}


/* -------------------------
 * Part 2: Visualization + summary stats from CSV
 * Requires: python + pandas + numpy + matplotlib
 * Outputs:
 *   - <sample>_gc_hist.png
 *   - <sample>_readlength_hist.png
 *   - <sample>_quality_hist.png
 *   - <sample>_summary_stats.txt
 * ------------------------- */
process processReadStatsViz {
    tag "$sample_name"
    publishDir "${params.out_dir}/${sample_name}/readstats_figures", mode: 'copy'

    input:
    tuple val(sample_name), path(csv)

    output:
    path "*"

    script:
    """
    python ${projectDir}/scripts/plot_read_stats.py \
      --input $csv \
      --outdir .
    """
}
