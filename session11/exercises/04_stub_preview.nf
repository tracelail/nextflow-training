// =============================================================================
// Exercise 04 — Stub Runs and Preview Mode
// =============================================================================
// Goal: Use -preview to validate workflow structure without execution,
//       then use -stub-run to test data flow without real tools.
//
// Run these commands in order:
//   nextflow lint exercises/04_stub_preview.nf          # Step 1: lint first
//   nextflow run exercises/04_stub_preview.nf -preview  # Step 2: structure check
//   nextflow run exercises/04_stub_preview.nf -stub-run # Step 3: data flow check
//   nextflow run exercises/04_stub_preview.nf           # Step 4: real run
//
// EXERCISE STEP 4: The SUMMARIZE_RESULTS process below does NOT have a
// stub: block yet. Add one that creates a placeholder output file.
// =============================================================================

// ---------------------------------------------------------------------------
// Process 1: Simulate an alignment step (e.g., mapping reads to a genome)
// In a real pipeline this would run bwa or STAR — here we use 'sort' as
// a stand-in that is always available on any Linux system.
// ---------------------------------------------------------------------------
process SIMULATE_ALIGNMENT {
    tag "${meta.id}"

    publishDir "${params.outdir}/aligned", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    // NOTE on val vs path:
    // In a real pipeline this would be:
    //   tuple val(meta), path("${meta.id}.bam")
    // Here we use path() correctly because we ARE creating a real file.
    // We only use val() for string values, not file paths.
    tuple val(meta), path("${meta.id}_aligned.txt")

    script:
    // Simulate alignment by sorting the text (as a stand-in for read alignment)
    """
    sort ${text_file} > ${meta.id}_aligned.txt
    echo "# Simulated alignment for ${meta.id} (${meta.type})" >> ${meta.id}_aligned.txt
    """

    // The stub: block creates an empty placeholder file.
    // This satisfies the output: declaration without running 'sort'.
    // Stub runs are used to test channel wiring, not tool behavior.
    stub:
    """
    touch ${meta.id}_aligned.txt
    """
}

// ---------------------------------------------------------------------------
// Process 2: Simulate a QC / flagstat step
// ---------------------------------------------------------------------------
process SIMULATE_QC {
    tag "${meta.id}"

    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(meta), path(aligned_file)

    output:
    tuple val(meta), path("${meta.id}_qc.txt")

    script:
    """
    LINE_COUNT=\$(wc -l < ${aligned_file})
    echo "QC report for ${meta.id}"     > ${meta.id}_qc.txt
    echo "Sample type: ${meta.type}"   >> ${meta.id}_qc.txt
    echo "Aligned lines: \${LINE_COUNT}" >> ${meta.id}_qc.txt
    echo "Status: PASS"                 >> ${meta.id}_qc.txt
    """

    stub:
    """
    touch ${meta.id}_qc.txt
    """
}

// ---------------------------------------------------------------------------
// Process 3: Aggregate QC reports across all samples
// ---------------------------------------------------------------------------
process SUMMARIZE_RESULTS {

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path qc_files    // collect() passes all QC files as a list

    output:
    path "summary.txt"

    script:
    """
    echo "=== QC Summary ===" > summary.txt
    echo "Samples processed: \$(echo '${qc_files}' | wc -w)" >> summary.txt
    echo ""                 >> summary.txt
    cat ${qc_files}         >> summary.txt
    """

    // EXERCISE STEP 4: This process has no stub: block.
    // Add one here that creates an empty summary.txt file.
    // After adding it, re-run: nextflow run exercises/04_stub_preview.nf -stub-run
    // The summary.txt file should appear in results/ (empty, but present).
    //
    stub:
    """
    touch summary.txt
    """
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------
workflow {
    // Build input channel from samplesheet
    samples_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, type: row.type]
            def tf   = file("${launchDir}/${row.text_file}")
            tuple(meta, tf)
        }

    // Step 1: Simulate alignment for all samples in parallel
    SIMULATE_ALIGNMENT(samples_ch)

    // Step 2: Run QC on each aligned output
    SIMULATE_QC(SIMULATE_ALIGNMENT.out)

    // Step 3: Collect all QC files, then produce one summary
    // collect() is a channel operator that waits for all elements
    // and emits them together as a single list to the next process.
    qc_files_ch = SIMULATE_QC.out
        .map { _meta, qc_file -> qc_file }  // drop the meta, keep only the file
        .collect()                          // wait for all samples, bundle into list

    SUMMARIZE_RESULTS(qc_files_ch)

    // View the summary on completion
    SUMMARIZE_RESULTS.out.view { f ->
        "\n--- Summary ---\n" + f.text + "---\n"
    }
}
