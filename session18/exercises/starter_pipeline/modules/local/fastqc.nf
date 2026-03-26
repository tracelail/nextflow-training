// modules/local/fastqc.nf
//
// ── VIOLATION: shell: block (deprecated since 24.11) ────────
// The shell: block uses !{var} for Nextflow variables and $var for Bash.
// In strict syntax, use script: with ${var} for Nextflow and \$var for Bash.
//
// Additionally: the output uses env FOO (unquoted) which is banned.

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
    // ── VIOLATION: env output name must be quoted ──────────
    // Fix: env 'FASTQC_VERSION'
    env 'FASTQC_VERSION',                emit: versions

    // ── VIOLATION: shell block ─────────────────────────────
    // Fix: convert to script: block, change !{var} to ${var},
    //      prefix Bash variables with \ to escape interpolation
    script:
    """
    fastqc \
        --threads ${task.cpus} \
        --outdir . \
        ${reads_1} ${reads_2}

    FASTQC_VERSION=\$(fastqc --version | sed 's/FastQC v//')
    """
}
