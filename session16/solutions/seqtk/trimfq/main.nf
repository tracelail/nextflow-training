process SEQTK_TRIMFQ {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_2' :
        'quay.io/biocontainers/seqtk:1.4--he4a0461_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"),           emit: trimmed
    tuple val("${task.process}"), val('seqtk'),
        eval('seqtk 2>&1 | grep "^Version" | sed "s/Version: //"'),
        emit: versions_seqtk, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqtk \\
        trimfq \\
        ${args} \\
        ${reads} \\
        | gzip --no-name > ${prefix}.fastq.gz
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip --no-name > ${prefix}.fastq.gz
    """
}
