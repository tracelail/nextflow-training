// =============================================================================
// Exercise 01 — Understanding -resume
// =============================================================================
// Goal: Observe exactly which tasks are cached and which re-execute
//       after a code change. Run this file twice — once fresh, once
//       with -resume — and watch the "cached: N" counts.
//
// Run:
//   nextflow run exercises/01_resume_demo.nf
//   nextflow run exercises/01_resume_demo.nf -resume
// =============================================================================

// 2026 syntax: lowercase 'channel' factory
// Explicit closure parameters (not implicit 'it')

// ---------------------------------------------------------------------------
// Process 1: Reverse the text in each file
// ---------------------------------------------------------------------------
process REVERSE_TEXT {
    // tag appears in the Nextflow log next to the task hash prefix
    tag "${meta.id}"

    // publishDir copies outputs to results/ after the task completes
    publishDir "${params.outdir}/reversed", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_reversed.txt")

    script:
    def sample_id = meta.id
    """
    rev ${text_file} > ${sample_id}_reversed.txt
    """

    // stub block: used with -stub-run to create placeholder output
    // without running the real command.
    // NOTE: In a real pipeline this would be 'path' output — using
    // path here is correct; val would only be used for simple string outputs.
    stub:
    def sample_id = meta.id
    """
    touch ${sample_id}_reversed.txt
    """
}

// ---------------------------------------------------------------------------
// Process 2: Count words in the original file
// ---------------------------------------------------------------------------
process COUNT_WORDS {
    tag "${meta.id}"

    publishDir "${params.outdir}/counts", mode: 'copy'

    input:
    tuple val(meta), path(text_file)

    output:
    tuple val(meta), path("${meta.id}_count.txt")

    script:
    // Exercise Step 3: Change the echo line below, then re-run with -resume.
    // Only COUNT_WORDS tasks should re-execute; REVERSE_TEXT stays cached.
    def sample_id = meta.id
    """
    echo "Words: \$(wc -w < ${text_file})" > ${sample_id}_count.txt
    """

    // EXERCISE STEP 3: Change the script above to:
    //   echo "Word count for ${sample_id}: \$(wc -w < ${text_file})" > ${sample_id}_count.txt
    // Then run: nextflow run exercises/01_resume_demo.nf -resume
    // Observe that REVERSE_TEXT is cached but COUNT_WORDS re-runs.

    stub:
    def sample_id = meta.id
    """
    touch ${sample_id}_count.txt
    """
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------
workflow {
    // Read the samplesheet CSV, one row per sample
    // splitCsv(header: true) gives us a map for each row
    // map transforms each map into a [meta, path] tuple
    samples_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id:   row.sample_id,
                type: row.type
            ]
            def text_file = file("${launchDir}/${row.text_file}")
            tuple(meta, text_file)
        }

    // Inspect the channel before it enters any process
    // Remove or comment out .view() once you are satisfied
    samples_ch.view { meta, f -> "INPUT: ${meta.id} -> ${f.name}" }

    // Run both processes on all samples in parallel
    REVERSE_TEXT(samples_ch)
    COUNT_WORDS(samples_ch)

    // View outputs as they complete
    REVERSE_TEXT.out.view { meta, f -> "REVERSED: ${meta.id} -> ${f.name}" }
    COUNT_WORDS.out.view  { meta, f -> "COUNTED:  ${meta.id} -> ${f.name}" }
}