#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "$projectDir/data"
params.out_dir   = params.out_dir   ?: "$projectDir/outputs"

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
    tag "$name"

    input:
    tuple path(fastq), val(name)

    output:
    path "${name}_nanoqc", emit: out

    script:
    """
    mkdir ${name}_nanoqc
    nanoQC -o ${name}_nanoqc ${fastq}
    """
}

/*
 * NanoPlot
 */
process nanoplot {
    tag "$name"

    input:
    tuple path(fastq), val(name)

    output:
    path "${name}_nanoplot", emit: out

    script:
    """
    mkdir ${name}_nanoplot
    NanoPlot --fastq ${fastq} --outdir ${name}_nanoplot
    """
}

/*
 * Read stats
 */
process readStats {
    tag "$name"

    input:
    tuple path(fastq), val(name)

    output:
    path "${name}_stats.txt", emit: out

    script:
    """
    awk 'NR%4==2 { print length(\$0) }' ${fastq} > ${name}_stats.txt
    """
}

/*
 * Stats visualization
 */
process readStatsViz {
    tag "plot"

    input:
    path stats

    output:
    path "stats_plot.png"

    script:
    """
    python3 custom_plot.py ${stats} stats_plot.png
    """
}
