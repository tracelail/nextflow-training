// =============================================================================
// Solution — 05_buggy_workflow_fixed.nf
// =============================================================================
// All 8 bugs fixed and annotated.
// Compare this file against your own fixed version.
//
// Bug summary:
//   #1 — Output filename mismatch         (PREPARE_SAMPLES)
//   #2 — Unescaped Bash variable          (ANALYZE_SAMPLE)
//   #3 — Deprecated shell: block          (SCORE_SAMPLE)
//   #4 — Wrong qualifier val vs path      (AGGREGATE_RESULTS)
//   #5 — Uppercase Channel factory        (workflow)
//   #6 — Missing def in closure           (workflow map)
//   #7 — Wrong process input source       (ANALYZE_SAMPLE call)
//   #8 — Nonexistent emit name            (AGGREGATE_RESULTS.out)
// =============================================================================

// ---------------------------------------------------------------------------
// Process 1: Prepare samples
// FIX #1: Output filename now matches what the script actually creates.
//   Before: path("${meta.id}_prepared.txt")   -- file that was NEVER created
//   After:  path("${meta.id}_clean.txt")       -- file the script DOES create
// ---------------------------------------------------------------------------
process PREPARE_SAMPLES {
    tag "${meta.id}"

    publishDir "${params.outdir}/prepared", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    // FIX #1: Filename matches what the script block produces
    tuple val(meta), path("${meta.id}_clean.txt")

    script:
    """
    grep -v "^#" ${text_file} > ${meta.id}_clean.txt
    echo "# Sample: ${meta.id} | Type: ${meta.type}" >> ${meta.id}_clean.txt
    """

    stub:
    """
    touch ${meta.id}_clean.txt
    """
}

// ---------------------------------------------------------------------------
// Process 2: Analyze each prepared sample
// FIX #2: Bash variable $WORD_COUNT escaped as \$WORD_COUNT.
//   Nextflow uses ${...} for its own variable interpolation inside process
//   scripts. Any Bash variable that should NOT be interpolated by Nextflow
//   must be written as \${VAR} or \$VAR so the backslash is consumed by
//   Nextflow's interpolation, leaving a literal $ for Bash to see.
// ---------------------------------------------------------------------------
process ANALYZE_SAMPLE {
    tag "${meta.id}"

    publishDir "${params.outdir}/analyzed", mode: 'copy'

    input:
    tuple val(meta), path(prepared_file)

    output:
    tuple val(meta), path("${meta.id}_analysis.txt")

    script:
    // FIX #2: \$WORD_COUNT and \$(wc ...) — backslash escapes Bash variables
    """
    WORD_COUNT=\$(wc -w < ${prepared_file})
    echo "Analysis for ${meta.id}:"     > ${meta.id}_analysis.txt
    echo "  Words:  \$WORD_COUNT"       >> ${meta.id}_analysis.txt
    echo "  Type:   ${meta.type}"       >> ${meta.id}_analysis.txt
    """

    stub:
    """
    touch ${meta.id}_analysis.txt
    """
}

// ---------------------------------------------------------------------------
// Process 3: Score each sample
// FIX #3: Replaced deprecated shell: block with script: block.
//   The shell: directive was deprecated in Nextflow 25.04.
//   In a script: block, Nextflow variables use ${var} and Bash variables
//   use \${var}. The if/else logic is identical — only the variable syntax
//   notation changes.
// ---------------------------------------------------------------------------
process SCORE_SAMPLE {
    tag "${meta.id}"

    publishDir "${params.outdir}/scores", mode: 'copy'

    input:
    tuple val(meta), path(analysis_file)

    output:
    tuple val(meta), path("${meta.id}_score.txt")

    // FIX #3: script: block replaces shell: block
    script:
    """
    if [ "${meta.type}" = "control" ]; then
        echo "SCORE=baseline" > ${meta.id}_score.txt
    else
        echo "SCORE=experimental" > ${meta.id}_score.txt
    fi
    """

    stub:
    """
    touch ${meta.id}_score.txt
    """
}

// ---------------------------------------------------------------------------
// Process 4: Aggregate all results
// FIX #4: Changed 'val' to 'path' for file inputs.
//   val is for string values (sample IDs, numbers, flags).
//   path is for files — it tells Nextflow to stage the file into the
//   task's work directory before the script runs.
//   Using val for a file means Nextflow passes the path as a string
//   but does NOT stage the actual file, so 'cat' fails with "No such file".
// FIX #8 (related): Added 'emit: report' to the output block so that
//   AGGREGATE_RESULTS.out.report works in the workflow.
// ---------------------------------------------------------------------------
process AGGREGATE_RESULTS {

    publishDir "${params.outdir}", mode: 'copy'

    input:
    // FIX #4: path (not val) — Nextflow stages these files into the work dir
    path analysis_files
    path score_files

    output:
    // FIX #8: emit name 'report' added so the workflow can reference it
    path "final_report.txt", emit: report

    script:
    """
    echo "=== Final Report ===" > final_report.txt
    echo "Date: \$(date)"       >> final_report.txt
    echo ""                     >> final_report.txt
    echo "--- Analysis ---"     >> final_report.txt
    cat ${analysis_files}       >> final_report.txt
    echo ""                     >> final_report.txt
    echo "--- Scores ---"       >> final_report.txt
    cat ${score_files}          >> final_report.txt
    """

    stub:
    """
    touch final_report.txt
    """
}

// ---------------------------------------------------------------------------
// Workflow — all bugs fixed
// ---------------------------------------------------------------------------
workflow {
    // FIX #5: Lowercase 'channel' factory (was: Channel.fromPath)
    raw_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            // FIX #6: 'def meta' — local variable, not global
            // Without 'def', meta becomes a script-global variable.
            // With concurrent execution, multiple closures writing to the
            // same global variable produce a race condition where the last
            // writer wins, corrupting earlier samples' metadata.
            def meta = [id: row.sample_id, type: row.type]
            def tf   = file("${projectDir}/${row.text_file}")
            tuple(meta, tf)
        }

    // Run the pipeline in the correct sequential order
    PREPARE_SAMPLES(raw_ch)

    // FIX #7: ANALYZE_SAMPLE now receives PREPARE_SAMPLES.out (not raw_ch)
    // The pipeline is sequential: raw -> PREPARE -> ANALYZE -> SCORE
    ANALYZE_SAMPLE(PREPARE_SAMPLES.out)

    SCORE_SAMPLE(ANALYZE_SAMPLE.out)

    // Collect all analysis and score files for aggregation
    analysis_ch = ANALYZE_SAMPLE.out
        .map { meta, f -> f }
        .collect()

    score_ch = SCORE_SAMPLE.out
        .map { meta, f -> f }
        .collect()

    AGGREGATE_RESULTS(analysis_ch, score_ch)

    // FIX #8: .report now resolves because we added emit: report above
    AGGREGATE_RESULTS.out.report.view { f ->
        "\nPipeline completed. Check ${f}\n"
    }
}
