nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "${projectDir}/data"
params.out_dir   = params.out_dir   ?: "${projectDir}/results"

workflow {

    Channel
        .fromPath("${params.fastq_dir}/*.{fastq,fq}", checkIfExists: true)
        .map { f ->
            def sample_id = f.name.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(sample_id, f)
        }
        .set { ch_reads }

    ADVANCED_QC(ch_reads)
    READ_METRICS(ch_reads) | VISUALIZE
}

process ADVANCED_QC {

    tag "${sample_id}"
    publishDir "${params.out_dir}/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(fastq)

    output:
    path "nanoqc",   optional: true
    path "nanoplot", optional: true

    script:
    """
    set -euo pipefail

    mkdir -p nanoqc nanoplot

    python ${projectDir}/scripts/advanced_qc.py \\
      --fastq "${fastq}" \\
      --nanoqc_dir "nanoqc" \\
      --nanoplot_dir "nanoplot"

    # Prefix outputs with sample_id_
    if [ -d "nanoplot" ]; then
      shopt -s nullglob
      for f in nanoplot/*; do
        base=\$(basename "\$f")
        [[ "\$base" == ${sample_id}_* ]] || mv "\$f" "nanoplot/${sample_id}_\${base}"
      done
      shopt -u nullglob
    fi

    if [ -d "nanoqc" ]; then
      shopt -s nullglob
      for f in nanoqc/*; do
        base=\$(basename "\$f")
        [[ "\$base" == ${sample_id}_* ]] || mv "\$f" "nanoqc/${sample_id}_\${base}"
      done
      shopt -u nullglob
    fi
    """
}

process READ_METRICS {

    tag "${sample_id}"
    publishDir "${params.out_dir}/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("${sample_id}_read_metrics.csv")

    script:
    """
    set -euo pipefail

    python ${projectDir}/scripts/read_metrics.py \\
      --input "${fastq}" \\
      --out_csv "${sample_id}_read_metrics.csv"
    """
}

process VISUALIZE {

    tag "${sample_id}"
    publishDir "${params.out_dir}/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(metrics_csv)

    output:
    path "${sample_id}_custom_qc_histograms.png"

    script:
    """
    set -euo pipefail
    export MPLBACKEND=Agg

    python ${projectDir}/scripts/visualize_metrics.py \\
      --input_csv "${metrics_csv}" \\
      --plot_png "${sample_id}_custom_qc_histograms.png"
    """
}
