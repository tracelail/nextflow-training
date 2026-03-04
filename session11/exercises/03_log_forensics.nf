// =============================================================================
// Exercise 03 — nextflow log Forensics
// =============================================================================
// Goal: Generate a multi-task execution, then use 'nextflow log' to
//       investigate it from multiple angles.
//
// After running this pipeline, work through the log commands in README.md
// Exercise 3 step by step.
//
// Run:
//   nextflow run exercises/03_log_forensics.nf
// =============================================================================

// ---------------------------------------------------------------------------
// Process 1: Count lines in each file
// ---------------------------------------------------------------------------
process COUNT_LINES {
    tag "${meta.id}"

    publishDir "${params.outdir}/line_counts", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_lines.txt"), emit: line_counts

    script:
    """
    LINE_COUNT=\$(wc -l < ${text_file})
    echo "${meta.id}: \${LINE_COUNT} lines" > ${meta.id}_lines.txt
    """

    stub:
    """
    echo "${meta.id}: 0 lines" > ${meta.id}_lines.txt
    """
}

// ---------------------------------------------------------------------------
// Process 2: Extract first line of each file
// ---------------------------------------------------------------------------
process EXTRACT_FIRST_LINE {
    tag "${meta.id}"

    publishDir "${params.outdir}/first_lines", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_first.txt"), emit: first_lines

    script:
    """
    head -1 ${text_file} > ${meta.id}_first.txt
    """

    stub:
    """
    echo "stub first line" > ${meta.id}_first.txt
    """
}

// ---------------------------------------------------------------------------
// Process 3: Combine into a summary report (collect all samples first)
// ---------------------------------------------------------------------------
process SUMMARIZE {

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path line_count_files   // collect() makes this a list of all files
    path first_line_files

    output:
    path "summary_report.txt", emit: report

    script:
    """
    echo "=== Pipeline Summary Report ===" > summary_report.txt
    echo "Generated: \$(date)"             >> summary_report.txt
    echo ""                                >> summary_report.txt
    echo "--- Line counts ---"             >> summary_report.txt
    cat ${line_count_files}                >> summary_report.txt
    echo ""                                >> summary_report.txt
    echo "--- First lines ---"             >> summary_report.txt
    cat ${first_line_files}                >> summary_report.txt
    """

    stub:
    """
    echo "stub summary" > summary_report.txt
    """
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------
workflow {
    // Build input channel
    samples_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, type: row.type]
            def tf   = file("${launchDir}/${row.text_file}")
            tuple(meta, tf)
        }

    // Run the two parallel processes on all samples
    COUNT_LINES(samples_ch)
    EXTRACT_FIRST_LINE(samples_ch)

    // collect() waits for ALL samples to complete, then bundles their
    // output files into a single list passed to SUMMARIZE as one task.
    // This is the scatter-gather pattern from Session 10.
    SUMMARIZE(
        COUNT_LINES.out.line_counts.map { meta, f -> f }.collect(),
        EXTRACT_FIRST_LINE.out.first_lines.map { meta, f -> f }.collect()
    )

    // Print the final report to the console as well
    SUMMARIZE.out.report.view { f ->
        "\n=== REPORT CONTENTS ===\n" + f.text + "=== END REPORT ===\n"
    }

    log.info """
    =========================================
    Pipeline complete!
    
    Investigate with:
      nextflow log                            # list all runs
      nextflow log <run_name>                 # list work dirs for this run
      nextflow log <run_name> -f 'process,exit,hash,duration'
      nextflow log <run_name> -F 'status == "COMPLETED"'
      nextflow log <run_name> -t scripts/log_template.html > results/provenance.html
    =========================================
    """.stripIndent()
}
