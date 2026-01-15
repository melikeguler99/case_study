#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/data/results"

workflow {

    Channel.fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName()
            name = name.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(f, name)
        }
        .set { fastq_ch }

    nanoqc(fastq_ch)
    nanoplot(fastq_ch)
    readStats(fastq_ch)
    readStatsViz(readStats.out)
}

/*
 * NanoQC
 */
process nanoqc {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    directory("${sample_id}/nanoqc")

    script:
    """
    mkdir -p ${sample_id}/nanoqc
    nanoqc $fastq
    mv nanoQC.html ${sample_id}/nanoqc/${sample_id}_NanoQC.html
    """
}

publishDir "${params.out_dir}", mode: 'copy'

/*
 * NanoPlot
 */
process nanoplot {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    directory("${sample_id}/nanoplot")

    script:
    """
    mkdir -p ${sample_id}/nanoplot
    NanoPlot --fastq $fastq -o ${sample_id}/nanoplot
    """
}

publishDir "${params.out_dir}", mode: 'copy'

/*
 * Custom Python: stats (FASTQ -> CSV)
 */
process readStats {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    tuple val(sample_id), path("${sample_id}_stats.csv")

    script:
    """
    python $projectDir/custom_python_scripts/custom_script.py \
      --input $fastq \
      --outdir .

    test -f ${sample_id}_stats.csv
    """
}

/*
 * Custom Python: visualization (CSV -> PNG)
 */
process readStatsViz {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(stats_csv)

    output:
    directory("${sample_id}/custom_plots")

    script:
    """
    mkdir -p ${sample_id}/custom_plots

    python $projectDir/custom_python_scripts/custom_script_vis.py \
      --input $stats_csv \
      --outdir ${sample_id}/custom_plots
    """
}

publishDir "${params.out_dir}", mode: 'copy'
