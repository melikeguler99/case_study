#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/outputs"

workflow {

    Channel.fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName()
            // handle .fastq.gz / .fq.gz as well
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
    path("${params.out_dir}/${sample_id}/nanoqc")

    script:
    """
    mkdir -p ${params.out_dir}/${sample_id}/nanoqc
    nanoqc $fastq
    # nanoqc writes nanoQC.html in the work dir
    mv nanoQC.html ${params.out_dir}/${sample_id}/nanoqc/${sample_id}_NanoQC.html
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
    path("${params.out_dir}/${sample_id}/nanoplot")

    script:
    """
    mkdir -p ${params.out_dir}/${sample_id}/nanoplot
    NanoPlot --fastq $fastq -o ${params.out_dir}/${sample_id}/nanoplot

    # rename output files to include sample_id
    cd ${params.out_dir}/${sample_id}/nanoplot
    for f in *.html *.png; do
        mv "\$f" "${sample_id}_\$f"
    done
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

    # custom_py.py writes <sample_id>_stats.csv into outdir
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
    path("${params.out_dir}/${sample_id}/custom_plots")

    script:
    """
    mkdir -p ${params.out_dir}/${sample_id}/custom_plots

    # copy/rename CSV
    cp $stats_csv ${params.out_dir}/${sample_id}/custom_plots/custom_results.csv

    python $projectDir/custom_python_scripts/custom_script_vis.py \
      --input ${params.out_dir}/${sample_id}/custom_plots/custom_results.csv \
      --outdir ${params.out_dir}/${sample_id}/custom_plots
    """
}
