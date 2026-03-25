// =============================================================================
// EXERCISE: Fill in all lines marked with # TODO
// Compare your finished file against modules/local/seqtk/seq/main.nf
// =============================================================================

process SEQTK_TRIMFQ {

    // TODO 1: Add the tag directive.
    // The tag should display the sample ID from the meta map in the execution log.
    tag "$meta.id"

    // TODO 2: Add the label directive.
    // seqtk trimfq is a single-threaded command.  Which label is appropriate?
    label 'process_single'

    // TODO 3: Add the container directives.
    // Use the same seqtk image as SEQTK_SEQ.
    // Image: quay.io/biocontainers/seqtk:1.4--he4a0461_2
    // Singularity: https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_2
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_2' :
        'quay.io/biocontainers/seqtk:1.4--he4a0461_2' }"

    input:
    // TODO 4: Define the input channel.
    // seqtk trimfq takes one FASTQ file per sample.
    // Shape: tuple val(meta), path(...)
    tuple val(meta), path(reads)

    output:
    // TODO 5: Define the trimmed output channel.
    // The output is a gzip-compressed FASTQ file.  Emit it as 'trimmed'.
    tuple val(meta), path("*.fastq.gz"), emit: trimmed

    // TODO 6: Add the topic channel version output (2026 pattern).
    // Use eval() to capture 'seqtk 2>&1 | grep "^Version" | sed "s/Version: //"'
    // Emit as: versions_seqtk, topic: versions
    tuple val("${task.process}"), val('seqtk'),
        eval('seqtk 2>&1 | grep "^Version" | sed "s/Version: //"'),
        emit: versions_seqtk, topic: versions

    // TODO 7: Add the when block.
    // Hint: this is identical in every nf-core module — copy it exactly.
    when:
        task.ext.when == null || task.ext.when

    script:
    // TODO 8: Define def args and def prefix before the heredoc.
    // Use ?: '' for args and ?: "${meta.id}" for prefix.
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO 9: Write the script heredoc.
    // Command: seqtk trimfq [args] [reads] | gzip --no-name > [prefix].fastq.gz
    """
    seqtk \\
        trimfq \\
        ${args} \\
        ${reads} \\
        | gzip --no-name > ${prefix}.fastq.gz
    """

    stub:
    // TODO 10: Write the stub block.
    // Must define the same def variables as script: block.
    // Must create the same output files as the output: block.
    // Use: echo "" | gzip --no-name > ${prefix}.fastq.gz
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip --no-name > ${prefix}.fastq.gz
    """
}
