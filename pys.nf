nextflow.enable.dsl=2

params.fastq_dir = params.fastq_dir ?: "${projectDir}/data"
params.out_dir   = params.out_dir   ?: "${projectDir}/results"

workflow {

    Channel
        .fromPath("${params.fastq_dir}/*.{fastq,fq,fastq.gz,fq.gz}", checkIfExists: true)
        .map { f ->
            def name = f.getBaseName()
            // handle .fastq.gz / .fq.gz
            if (name.endsWith(".fastq")) name = name[0..-6]
            if (name.endsWith(".fq"))    name = name[0..-4]
            tuple(name, f)
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

    /*
      We create exactly:
        nanoqc/   (NanoQC output)
        nanoplot/ (NanoPlot output)
      and publish them into: results/<sample_id>/
    */

    script:
    """
    set -euo pipefail

    mkdir -p nanoqc nanoplot

    echo "=== Processing ${sample_id} (ADVANCED_QC) ==="

    echo "🧪 Running NanoQC..."
    python ${projectDir}/scripts/advanced_qc.py \\
      --fastq "${fastq}" \\
      --nanoqc_dir "nanoqc" \\
      --nanoplot_dir "nanoplot"

    echo "✔ Advanced QC finished for ${sample_id}"
    """
}

process CUSTOM_QC {

    tag "${sample_id}"
    publishDir "${params.out_dir}/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(fastq)

    output:
    path "read_metrics.csv"

    script:
    """
    set -euo pipefail
    export MPLBACKEND=Agg

    echo "=== Processing ${sample_id} (CUSTOM_QC) ==="

    python ${projectDir}/scripts/custom_qc.py \\
      --input "${fastq}" \\
      --out_csv "read_metrics.csv"

    echo "✔ Custom QC finished for ${sample_id}"
    """
}
