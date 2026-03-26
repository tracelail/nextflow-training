// modules/local/trim_reads.nf
//
// ── VIOLATION: implicit 'it' in closure ─────────────────────
// The ext.args line uses { it } implicitly.
// Fix: { args -> args }

process TRIM_READS {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::trim-galore=0.6.10'
    container 'quay.io/biocontainers/trim-galore:0.6.10--hdfd78af_0'

    input:
    tuple val(meta), path(reads_1), path(reads_2)
    val   genome_build

    output:
    tuple val(meta), path("*_trimmed.fq.gz"), emit: reads
    path  "*_trimming_report.txt",            emit: log
    // tuple val("${task.process}"), val('trim-galore'),
    //       eval('trim_galore --version | tail -1 | sed "s/.*version //; s/ .*//"'),
    //       emit: versions, topic: versions

    script:
    // ── VIOLATION: implicit 'it' ──────────────────────────
    // The next line references 'it' implicitly in a closure context.
    // (In practice this might appear in ext.args resolution — shown here
    //  for exercise purposes.)
    def extra_args = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: meta.id
    """
    trim_galore \\
        --paired \\
        --cores ${task.cpus} \\
        ${extra_args} \\
        --basename ${prefix} \\
        ${reads_1} \\
        ${reads_2}
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_R1_trimmed.fq.gz
    touch ${prefix}_R2_trimmed.fq.gz
    touch ${prefix}_trimming_report.txt
    echo "0.6.10"
    """
}
