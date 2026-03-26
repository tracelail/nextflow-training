// modules/local/fastqc.nf  (SOLUTION — strict-syntax compliant)
//
// Changes from starter version:
//   ✓ shell: block → script: block
//   ✓ !{var} → ${var}  (Nextflow variable interpolation)
//   ✓  $var  → \$var   (Bash variables escaped)
//   ✓ env FASTQC_VERSION → env 'FASTQC_VERSION'  (quoted)

process FASTQC {
    tag "$meta.id"
    label 'process_low'

    conda 'bioconda::fastqc=0.12.1'
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads_1), path(reads_2)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip
    // ✓ env name is now quoted
    env 'FASTQC_VERSION',            emit: versions

    // ✓ script: block replaces shell:
    // Key difference:
    //   Nextflow variables  →  ${var}   (same as before)
    //   Bash variables      →  \$VAR    (must be escaped)
    script:
    """
    fastqc \\
        --threads ${task.cpus} \\
        --outdir . \\
        ${reads_1} ${reads_2}

    FASTQC_VERSION=\$(fastqc --version | sed 's/FastQC v//')
    """

    stub:
    """
    touch stub_fastqc.html stub_fastqc.zip
    FASTQC_VERSION="0.12.1"
    """
}
