#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/outputs"

workflow {

    Channel.fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName().replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(f, name)
        }
        .set { fastq_ch }

    nanoqc(fastq_ch)
    nanoplot(fastq_ch)
    readStats(fastq_ch)
    readStatsViz(readStats.out)
}

process nanoqc {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    path("*.html")

    publishDir "${params.out_dir}/${sample_id}/nanoqc", mode: 'copy'

    script:
    """
    nanoqc $fastq
    """
}

process nanoplot {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    path("${sample_id}_*.png")
    path("${sample_id}_*.html")

    publishDir "${params.out_dir}/${sample_id}/nanoplot", mode: 'copy'

    script:
    """
    NanoPlot --fastq $fastq -o .

    for f in *.html *.png; do
        mv "\$f" "${sample_id}_\$f"
    done
    """
}

process readStats {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    tuple val(sample_id), path("${sample_id}_stats.csv")

    script:
    """
    python $projectDir/custom_python_scripts/custom_py.py \
        --input $fastq \
        --outdir .

    test -f ${sample_id}_stats.csv
    """
}

process readStatsViz {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(stats_csv)

    output:
    path("custom_results.csv")
    path("${sample_id}_*.png")

    publishDir "${params.out_dir}/${sample_id}/custom_plots", mode: 'copy'

    script:
    """
    mv $stats_csv custom_results.csv

    python $projectDir/custom_python_scripts/custom_script_vis.py \
        --input custom_results.csv \
        --outdir .

    for f in *.png; do
        mv "\$f" "${sample_id}_\$f"
    done
    """
}
