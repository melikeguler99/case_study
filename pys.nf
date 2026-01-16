nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "${projectDir}/data"
params.out_dir   = params.out_dir   ?: "${projectDir}/results"

workflow {

    Channel
        .fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            // Robust sample_id (no trailing dots, handles .fastq/.fq + optional .gz)
            def sample_id = f.name.replaceFirst(/(\.fastq|\.fq)(\.gz)?$/, '')
            tuple(sample_id, f)
        }
        .set { ch_reads }

    ADVANCED_QC(ch_reads)
    CUSTOM_QC(ch_reads)
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

    echo "=== Processing ${sample_id} (ADVANCED_QC) ==="

    python ${projectDir}/scripts/advanced_qc.py \\
      --fastq "${fastq}" \\
      --nanoqc_dir "nanoqc" \\
      --nanoplot_dir "nanoplot"

    # -------------------------
    # Prefix NanoPlot outputs with sample_id_
    # -------------------------
    if [ -d "nanoplot" ]; then
      shopt -s nullglob
      for f in nanoplot/*; do
        base=\$(basename "\$f")
        if [[ "\$base" != ${sample_id}_* ]]; then
          mv "\$f" "nanoplot/${sample_id}_\${base}"
        fi
      done
      shopt -u nullglob
    fi

    # -------------------------
    # Prefix NanoQC outputs with sample_id_
    # -------------------------
    if [ -d "nanoqc" ]; then
      shopt -s nullglob
      for f in nanoqc/*; do
        base=\$(basename "\$f")
        if [[ "\$base" != ${sample_id}_* ]]; then
          mv "\$f" "nanoqc/${sample_id}_\${base}"
        fi
      done
      shopt -u nullglob
    fi

    echo "✔ Advanced QC finished for ${sample_id}"
    """
}

process CUSTOM_QC {

    tag "${sample_id}"
    publishDir "${params.out_dir}/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(fastq)

    output:
    path "${sample_id}_read_metrics.csv"
    path "${sample_id}_custom_qc_histograms.png"

    script:
    """
    set -euo pipefail
    export MPLBACKEND=Agg

    echo "=== Processing ${sample_id} (CUSTOM_QC) ==="

    python ${projectDir}/scripts/custom_qc.py \\
      --input "${fastq}" \\
      --out_csv "${sample_id}_read_metrics.csv" \\
      --plot_png "${sample_id}_custom_qc_histograms.png"

    echo "✔ Custom QC finished for ${sample_id}"
    """
}
