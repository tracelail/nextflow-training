/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL MODULE: COLLECT_RESULTS
    ─────────────────────────────────────────────────────────────────────────────────
    Aggregates all uppercased greeting files into a single summary file.
    Step 3 of 3 in the greetings pipeline. This is the "gather" step of
    a scatter-gather pattern.

    IMPORTANT DIFFERENCE FROM SESSIONS 3 AND 10:
    This process does NOT carry a meta map. It receives a list of plain
    path items (after the workflow strips meta with .map { meta, file -> file }).

    input: path(upper_files)   ← a collection of files, NO meta tuple

    Why no meta here? Because COLLECT_RESULTS aggregates ALL samples into
    ONE output. The per-sample metadata (meta.id) is no longer meaningful
    when you are producing a single file summarising everything.

    The scatter-gather pattern:
        Scatter:  SAY_HELLO runs 6 times (once per sample) → 6 tasks
        Process:  CONVERT_UPPER runs 6 times → 6 tasks
        Gather:   COLLECT_RESULTS runs ONCE (all files collected) → 1 task
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process COLLECT_RESULTS {

    label 'process_single'

    input:
    // path(upper_files) receives multiple files at once because the workflow
    // called .collect() before passing the channel to this process.
    // Nextflow stages all files into the work directory for this single task.
    path upper_files

    output:
    path "all_greetings.txt", emit: all
    path "versions.yml",      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo "=== All Greetings (uppercased) ===" > all_greetings.txt
    echo "Generated: \$(date)" >> all_greetings.txt
    echo "" >> all_greetings.txt
    cat ${upper_files} ${args} >> all_greetings.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch all_greetings.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
