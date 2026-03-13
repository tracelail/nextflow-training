/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL MODULE: CONVERT_UPPER
    ─────────────────────────────────────────────────────────────────────────────────
    Uppercases the contents of a greeting text file.
    Step 2 of 3 in the greetings pipeline.

    SESSION 3 COMPARISON:
    Original Session 3 process had:
        output: val(upper_text)   ← a val output: string produced by the script

    This version uses:
        output: path("*.txt")    ← a path output: a file produced by the script

    WHY THE CHANGE? In nf-core pipelines, process outputs are almost always
    files (path) rather than values (val). This is because:
    1. Files are stored in the work directory and can be resumed from cache.
    2. Files can be published to the output directory with publishDir.
    3. Large text content should not be passed through channels as strings.
    Session 3 used val as a teaching simplification. Real pipelines use path.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CONVERT_UPPER {

    tag "$meta.id"
    label 'process_single'

    input:
    // The output from SAY_HELLO: a meta map and a path to the greeting file
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path("${prefix}.upper.txt"), emit: upper
    path "versions.yml",                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    tr '[:lower:]' '[:upper:]' ${args} < ${txt} > ${prefix}.upper.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.upper.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
