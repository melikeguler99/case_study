#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Default directories if not provided
params.fastq_dir = params.fastq_dir ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/outputs"

workflow {

    // Find FASTQ files
    Channel.fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName()
            name = name.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(f, name)
        }
        .set { fastq_ch }

    // Run processes
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
    path("*.html"), publishDir: "${params.out_dir}/${sample_id}/nanoqc", mode: 'copy'

    script:
    """
    nanoqc $fastq
    """
}

/*
 * NanoPlot
 */
process nanoplot {
    tag "$sample_id"

    input:
    tuple path(fastq), val(sample_id)

    output:
    path("*"), publishDir: "${params.out_dir}/${sample_id}/nanoplot", mode: 'copy'

    script:
    """
    NanoPlot --fastq $fastq -o .
    for f in *.html *.png; do mv "\$f" "${sample_id}_\$f"; done
    """
}


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
    python $projectDir/custom_python_scripts/custom_py.py \
        --input $fastq \
        --outdir .

    # Ensure CSV exists
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
    path("*"), publishDir: "${params.out_dir}/${sample_id}/custom_plots", mode: 'copy'

    script:
    """
    python $projectDir/custom_python_scripts/custom_script_vis.py \
        --input $stats_csv \
        --outdir .

    # Rename PNG to include sample name
    for f in *.png; do mv "\$f" "${sample_id}_\$f"; done

    # Rename CSV to custom_results.csv
    mv $stats_csv custom_results.csv
    """
}
