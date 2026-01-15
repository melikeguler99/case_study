#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// MANUAL paths
params.fastq_dir = "/Users/melike/Desktop/case_study_2026massive/data"
params.out_dir   = "/Users/melike/Desktop/case_study_2026massive/results_5"
params.script_dir = "/Users/melike/Desktop/case_study_2026massive/custom_python_scripts"

workflow {

    Channel
        .fromPath("${params.fastq_dir}/*.fastq.gz", checkIfExists: true)
        .map { file ->
            def name = file.getBaseName().replaceFirst(/\.fastq\.gz$/, '')
            tuple(file, name)
        }
        .set { fastq_ch }

    nanoqc(fastq_ch)
    nanoplot(fastq_ch)
    readStats(fastq_ch)
    readStatsViz(readStats.out)
}

process nanoqc {
    tag "$id"
    input:
        tuple path(fq), val(id)
    output:
        path("${id}/nanoqc")
    publishDir "${params.out_dir}", mode: 'copy'
    script:
    """
    mkdir -p ${id}/nanoqc
    nanoqc $fq
    mv nanoQC.html ${id}/nanoqc/${id}_NanoQC.html
    """
}

process nanoplot {
    tag "$id"
    input:
        tuple path(fq), val(id)
    output:
        path("${id}/nanoplot")
    publishDir "${params.out_dir}", mode: 'copy'
    script:
    """
    mkdir -p ${id}/nanoplot
    NanoPlot --fastq $fq -o ${id}/nanoplot
    """
}

process readStats {
    tag "$id"
    input:
        tuple path(fq), val(id)
    output:
        tuple val(id), path("${id}_stats.csv")
    publishDir "${params.out_dir}", mode: 'copy'
    script:
    """
    python ${params.script_dir}/custom_script.py \
        --input $fq \
        --outdir .

    test -f ${id}_stats.csv
    """
}

process readStatsViz {
    tag "$id"
    input:
        tuple val(id), path(csv)
    output:
        path("${id}/custom_plots")
    publishDir "${params.out_dir}", mode: 'copy'
    script:
    """
    mkdir -p ${id}/custom_plots
    python ${params.script_dir}/custom_script_vis.py \
        --input $csv \
        --outdir ${id}/custom_plots
    """
}
