#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.fastq_dir  = params.fastq_dir ?: "$projectDir/data"
params.out_dir    = params.out_dir   ?: "$projectDir/outputs"

workflow {

    Channel
        .fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def s = f.getBaseName()
            s = s.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(s, f)
        }
        .set { fastq_ch }

    nanoqc_ch      = nanoqc(fastq_ch)
    nanoplot_ch    = nanoplot(fastq_ch)
    stats_ch       = readStats(fastq_ch)
    readStatsViz(stats_ch)
}

/*
 * NanoQC
 */
process nanoqc {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(fastq)

    conda 'env.yml'

    output:
    path("${sample_id}_NanoQC.html")

    publish:
        path "${sample_id}_NanoQC.html"
        into "${params.out_dir}/${sample_id}/nanoqc"
        mode "copy"

    script:
    """
    nanoqc --outdir . $fastq
    mv NanoQC.html ${sample_id}_NanoQC.html
    """
}

/*
 * NanoPlot
 */
process nanoplot {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(fastq)

    conda 'env.yml'

    output:
    path("${sample_id}_nanoplot_*")

    publish:
        path "${sample_id}_nanoplot_*"
        into "${params.out_dir}/${sample_id}/nanoplot"
        mode "copy"

    script:
    """
    NanoPlot --fastq $fastq -o .
    for f in *; do mv "\$f" "${sample_id}_nanoplot_\$f"; done
    """
}

/*
 * Custom Python stats
 */
process readStats {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(fastq)

    conda 'env.yml'

    output:
    tuple val(sample_id), path("${sample_id}_stats.csv")

    script:
    """
    python $projectDir/custom_python_scripts/custom_py.py \
        --input $fastq \
        --outdir .

    # Ensures file exists & formatted correctly
    mv stats.csv ${sample_id}_stats.csv
    """
}

/*
 * Custom Python visualization
 */
process readStatsViz {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(stats_csv)

    conda 'env.yml'

    output:
    path("${sample_id}_custom_*")

    publish:
        path "${sample_id}_custom_*"
        into "${params.out_dir}/${sample_id}/custom_plots"
        mode "copy"

    script:
    """
    python $projectDir/custom_python_scripts/custom_script_vis.py \
        --input $stats_csv \
        --outdir .

    for f in *.png; do mv "\$f" "${sample_id}_custom_\$f"; done
    mv $stats_csv ${sample_id}_custom_results.csv
    """
}
