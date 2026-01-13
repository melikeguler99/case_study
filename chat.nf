params.fastq_dir = "${projectDir}/data"
params.out_dir   = "${projectDir}/data/results"

workflow {
    Channel.fromPath("${params.fastq_dir}/*.fastq*")
        .map { file ->
            def sample_name = file.getBaseName().replaceFirst(/\.fastq$/, '')  // handles .fastq.gz too
            tuple(file, sample_name)
        }
        .set { fastq_ch }

    processNanoQC(fastq_ch)
    processNanoPlot(fastq_ch)
}

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

