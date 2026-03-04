// =============================================================================
// Exercise 02 — Cache Invalidation
// =============================================================================
// Goal: Deliberately trigger three of the five cache-breakers and observe
//       the results. Then apply the correct fix for each.
//
// Run:
//   nextflow run exercises/02_invalidation.nf
//   (then follow the instructions in README.md Exercise 2)
//
// IMPORTANT: This file contains a deliberate race condition in COMBINE_RESULTS.
//            It is there so you can observe the bug. The fix is shown in the
//            comments — apply it when instructed.
// =============================================================================

// ---------------------------------------------------------------------------
// Process A: Measure text length — demonstrates cache 'lenient'
// ---------------------------------------------------------------------------
process MEASURE_LENGTH {
    tag "${meta.id}"

    // TRY IT: After running once, add 'lenient' here:
    cache 'lenient'
    // Then: touch data/sampleA.txt && nextflow run ... -resume
    // With 'lenient', the touched file does NOT invalidate the cache.
    // Without it, any touch causes a cache miss.

    publishDir "${params.outdir}/lengths", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_length.txt")

    script:
    """
    wc -c < ${text_file} | tr -d ' ' > ${meta.id}_length.txt
    """

    stub:
    """
    echo "42" > ${meta.id}_length.txt
    """
}

// ---------------------------------------------------------------------------
// Process B: Uppercase the text — stable process (should always cache)
// ---------------------------------------------------------------------------
process UPPERCASE_TEXT {
    tag "${meta.id}"

    publishDir "${params.outdir}/uppercase", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_upper.txt")

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${text_file} > ${meta.id}_upper.txt
    """

    stub:
    """
    touch ${meta.id}_upper.txt
    """
}

// ---------------------------------------------------------------------------
// Process C: Combine length + uppercase — demonstrates non-determinism
//
// BUG EXPLANATION:
//   MEASURE_LENGTH and UPPERCASE_TEXT run concurrently for each sample.
//   Their outputs arrive in the channel in whatever order they finish.
//   Without join(), COMBINE_RESULTS may receive mismatched pairs:
//     e.g., sampleA's length with sampleB's uppercase text.
//   This produces different task hashes each run -> resume breaks.
//
// FIX (apply after observing the bug):
//   Replace the direct channel pair with join() as shown below.
// ---------------------------------------------------------------------------
process COMBINE_RESULTS {
    tag "${meta.id}"

    publishDir "${params.outdir}/combined", mode: 'copy'

    input:
    // NOTE: This process takes TWO separate tuples — one from each upstream process
    tuple val(meta),       path(length_file)
    tuple val(meta2),      path(upper_file)

    output:
    tuple val(meta), path("${meta.id}_combined.txt")

    script:
    """
    echo "=== ${meta.id} (${meta.type}) ===" > ${meta.id}_combined.txt
    echo "Characters: \$(cat ${length_file})"  >> ${meta.id}_combined.txt
    echo ""                                    >> ${meta.id}_combined.txt
    cat ${upper_file}                          >> ${meta.id}_combined.txt
    """

    stub:
    """
    touch ${meta.id}_combined.txt
    """
}

// ---------------------------------------------------------------------------
// Process D: Global variable race condition demo
//
// RACE CONDITION EXPLANATION:
//   The variable SHARED_COUNTER is declared WITHOUT 'def' inside the closure.
//   In Nextflow, a variable without 'def' in a closure becomes global to the
//   script. Since closures execute concurrently (one per channel element),
//   two concurrent closures can overwrite each other's value of SHARED_COUNTER.
//   Result: non-deterministic outputs -> different task hashes each run.
//
// FIX:
//   Change:  SHARED_COUNTER = 0
//   To:      def SHARED_COUNTER = 0
// ---------------------------------------------------------------------------
process SHOW_RACE_CONDITION {
    tag "${meta.id}"
    maxForks 4    // Allow all 4 to run simultaneously to expose the race

    publishDir "${params.outdir}/race_demo", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_race.txt")

    script:
    """
    echo "Sample: ${meta.id}" > ${meta.id}_race.txt
    echo "Type: ${meta.type}" >> ${meta.id}_race.txt
    """

    stub:
    """
    touch ${meta.id}_race.txt
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

    // Run the two independent processes
    MEASURE_LENGTH(samples_ch)
    UPPERCASE_TEXT(samples_ch)

    // -------------------------------------------------------------------------
    // CURRENT (BUGGY) VERSION: channels are joined by position, not by key.
    // Run multiple times and compare task hashes with:
    //   nextflow log <run1> -f 'process,tag,hash'
    //   nextflow log <run2> -f 'process,tag,hash'
    // COMBINE_RESULTS will have different hashes each run.
    // -------------------------------------------------------------------------
    COMBINE_RESULTS(
        MEASURE_LENGTH.out,
        UPPERCASE_TEXT.out
    )

    // -------------------------------------------------------------------------
    // FIXED VERSION (uncomment after observing the bug):
    // join() pairs elements by their first element (the meta map).
    // Both channels must have matching meta maps for join() to work.
    //
    // joined_ch = MEASURE_LENGTH.out.join(UPPERCASE_TEXT.out)
    // // joined_ch emits: [meta, length_file, upper_file]
    // // We need to split it into two tuples for COMBINE_RESULTS input:
    // COMBINE_RESULTS(
    //     joined_ch.map { meta, lf, uf -> tuple(meta, lf) },
    //     joined_ch.map { meta, lf, uf -> tuple(meta, uf) }
    // )
    // -------------------------------------------------------------------------

    // Race condition demo — run this and observe its channel values
    // The non-determinism here is in the Groovy map closure, not the process
    // Demonstrate in the workflow using map:
    samples_ch
        .map { meta, _tf ->
            // BUG: No 'def' — SHARED_COUNTER is global, shared across concurrent closures
            // FIX: Change to: def SHARED_COUNTER = 0
            def SHARED_COUNTER = 0
            SHARED_COUNTER = SHARED_COUNTER + meta.id.length()
            tuple(meta, SHARED_COUNTER)
        }
        .view { meta, count -> "RACE DEMO ${meta.id}: counter=${count}" }

    SHOW_RACE_CONDITION(samples_ch)
}
