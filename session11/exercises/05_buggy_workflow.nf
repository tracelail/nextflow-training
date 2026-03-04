// =============================================================================
// Exercise 05 — The Buggy Workflow (Challenge)
// =============================================================================
// Goal: Find and fix ALL 8 deliberate bugs using the four-phase method:
//   Phase 1: nextflow lint exercises/05_buggy_workflow.nf
//   Phase 2: nextflow run exercises/05_buggy_workflow.nf -preview
//   Phase 3: nextflow run exercises/05_buggy_workflow.nf -stub-run
//   Phase 4: nextflow run exercises/05_buggy_workflow.nf
//
// DO NOT scroll to the solutions file until you have made a genuine attempt.
// Use the bug inventory table in README.md to track your findings.
//
// HINT: The bugs are spread across all four phases. Some will appear in lint,
//       some only in preview, some only during stub-run, some only in full run.
//       Use the four-phase method in order — do not skip phases.
// =============================================================================

// ---------------------------------------------------------------------------
// Bug hunt begins here. Proceed carefully.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Process 1: Prepare samples — clean and tag each text file
// ---------------------------------------------------------------------------
process PREPARE_SAMPLES {
    tag "${meta.id}"

    publishDir "${params.outdir}/prepared", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    // BUG #1: The output filename does not match what the script creates.
    // The script creates "${meta.id}_clean.txt" but the output block declares
    // something different. Find it and fix the mismatch.
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
// ---------------------------------------------------------------------------
process ANALYZE_SAMPLE {
    tag "${meta.id}"

    publishDir "${params.outdir}/analyzed", mode: 'copy'

    input:
    tuple val(meta), path(prepared_file)

    output:
    tuple val(meta), path("${meta.id}_analysis.txt")

    script:
    // BUG #2: Bash variable not properly escaped — Nextflow will try to
    // interpolate $WORD_COUNT as a Nextflow variable, which doesn't exist.
    // Bash variables inside process scripts must be escaped with a backslash.
    """
    WORD_COUNT = \$(wc -w < ${prepared_file})
    echo "Analysis for ${meta.id}:"     > ${meta.id}_analysis.txt
    echo "  Words:  \${WORD_COUNT}"       >> ${meta.id}_analysis.txt
    echo "  Type:   ${meta.type}"      >> ${meta.id}_analysis.txt
    """

    stub:
    """
    touch ${meta.id}_analysis.txt
    """
}

// ---------------------------------------------------------------------------
// Process 3: Score each sample (control vs treatment scoring)
// ---------------------------------------------------------------------------
process SCORE_SAMPLE {
    tag "${meta.id}"

    publishDir "${params.outdir}/scores", mode: 'copy'

    input:
    tuple val(meta), path(analysis_file)

    output:
    tuple val(meta), path("${meta.id}_score.txt")

    // BUG #3: 'shell' block is deprecated since Nextflow 25.04.
    // This should be a 'script:' block. The shell: syntax also changes
    // how variables work (uses !{var} instead of ${var}).
    // Replace this entire shell: block with the equivalent script: block.
    script:
    '''
    if [ "${meta.type}" = "control" ]; then
        echo "SCORE=baseline" > ${meta.id}_score.txt
    else
        echo "SCORE=experimental" > ${meta.id}_score.txt
    fi
    '''

    stub:
    """
    touch ${meta.id}_score.txt
    """
}

// ---------------------------------------------------------------------------
// Process 4: Aggregate all results into a final report
// ---------------------------------------------------------------------------
process AGGREGATE_RESULTS {

    publishDir "${params.outdir}", mode: 'copy'

    input:
    // BUG #4: Wrong qualifier — 'val' is used for string values, not files.
    // When a process outputs or receives files, the qualifier must be 'path'.
    // This will fail because Nextflow cannot stage a val as a file.
    path analysis_files
    path score_files

    output:
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
// Workflow
// ---------------------------------------------------------------------------
workflow {
    // BUG #5: Channel factory uses uppercase 'Channel' (deprecated).
    // Must use lowercase 'channel' for all factories.
    raw_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            // BUG #6: Variable declared without 'def' inside a closure.
            // This makes 'meta' a global variable — causing a race condition
            // when multiple samples are processed concurrently.
            def meta = [id: row.sample_id, type: row.type]
            def tf = file("${launchDir}/${row.text_file}")
            tuple(meta, tf)
        }

    // Run the processing pipeline
    PREPARE_SAMPLES(raw_ch)

    // BUG #7: ANALYZE_SAMPLE is fed from raw_ch instead of PREPARE_SAMPLES.out.
    // The pipeline should be sequential: raw -> PREPARE -> ANALYZE -> SCORE.
    // Fix: ANALYZE_SAMPLE should receive PREPARE_SAMPLES.out, not raw_ch.
    ANALYZE_SAMPLE(raw_ch)

    SCORE_SAMPLE(ANALYZE_SAMPLE.out)

    // Collect all analysis and score files, drop meta for aggregation
    analysis_ch = ANALYZE_SAMPLE.out
        .map { _analysis_meta, f -> f }
        .collect()

    score_ch = SCORE_SAMPLE.out
        .map { _score_meta, f -> f }
        .collect()

    // BUG #8: The emit name 'report' doesn't exist on AGGREGATE_RESULTS.out.
    // AGGREGATE_RESULTS has only one output (final_report.txt) and no emit: name.
    // Either add an emit: name to the output block, or access the output directly.
    AGGREGATE_RESULTS(analysis_ch, score_ch)
    AGGREGATE_RESULTS.out.report.view { f ->
        "\nPipeline completed. Check ${f}\n"
    }
}