process SEQTK_SEQ {
    tag "$meta.id"
    label 'process_single'

    // Prefer quay.io/biocontainers over Docker Hub biocontainers/
    // Singularity URL uses depot.galaxyproject.org as the mirror
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_2' :
        'quay.io/biocontainers/seqtk:1.4--he4a0461_2' }"

    input:
    // tuple is the standard nf-core input shape: [meta_map, file(s)]
    tuple val(meta), path(reads)

    output:
    // emit: names let the calling workflow reference outputs by name
    // e.g.  SEQTK_SEQ.out.fasta
    tuple val(meta), path("*.fasta.gz"), emit: fasta

    // 2026 topic channel version output — replaces the old versions.yml heredoc.
    // eval() runs the quoted shell command AFTER the script block completes and
    // captures its stdout as a val.  topic: versions broadcasts this tuple to
    // every process in the pipeline automatically — no ch_versions.mix() needed.
    // tuple val("${task.process}"), val('seqtk'),
    //     eval('seqtk 2>&1 | grep "^Version" | sed "s/Version: //"'),
    //     emit: versions_seqtk, topic: versions

    // The when block is identical in every nf-core module. Never change it.
    when:
    task.ext.when == null || task.ext.when

    script:
    // IMPORTANT: always extract meta fields into local def variables BEFORE the
    // triple-quoted heredoc.  Using ${meta.id} directly inside the heredoc causes
    // Bash glob substitution, which silently produces wrong filenames.
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqtk \\
        seq \\
        -a \\
        ${args} \\
        ${reads} \\
        | gzip --no-name > ${prefix}.fasta.gz
    """

    // stub: block is MANDATORY in every nf-core module.
    // It runs when nextflow is invoked with -stub and must create every file
    // that appears in the output: block.  Use "echo "" | gzip" for .gz files —
    // never "touch file.gz", which produces a zero-byte file that is not a
    // valid gzip archive and will fail nf-test's gz parser.
    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip --no-name > ${prefix}.fasta.gz
    """
}
