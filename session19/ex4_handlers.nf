// ex4_handlers.nf
// Session 19 — Bonus: onComplete and onError handlers
//
// Demonstrates two styles of completion handler:
//   Style A: Classic closure syntax  (works in ALL Nextflow versions, ≥ 23.x)
//   Style B: Section syntax          (new in 25.10, requires strict parser)
//
// This file uses Style A so it runs without NXF_SYNTAX_PARSER=v2.
// See the comments at the bottom for how Style B looks under strict syntax.
//
// Run: nextflow run ex4_handlers.nf
// To see the error handler: nextflow run ex4_handlers.nf --trigger_error

params.input_dir    = "${projectDir}/data"
params.trigger_error = false

process TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.txt"), emit: reads

    script:
    """
    echo "TRIMMED: \$(cat ${reads})" > ${meta.id}.trimmed.txt
    """
}

process MAYBE_FAIL {
    // This process deliberately fails when --trigger_error true is passed.
    // Use it to test the onError handler.

    input:
    val trigger

    output:
    val "ok", emit: status

    script:
    if (trigger.toString() == 'true')
        """
        echo "About to fail deliberately..." >&2
        exit 1
        """
    else
        """
        echo "No error triggered."
        """
}

// ── Style A: classic closure syntax ──────────────────────────────────────────
// Define handlers OUTSIDE the workflow block using the workflow object.
// This works in Nextflow ≥ 23.x without any feature flags.

workflow.onComplete {
    println ""
    println "╔══════════════════════════════════════════════════╗"
    println "║            Pipeline Complete                     ║"
    println "╠══════════════════════════════════════════════════╣"
    println "║  Status    : ${workflow.success ? '✅  SUCCESS' : '❌  FAILED '}"
    println "║  Duration  : ${workflow.duration}"
    println "║  Completed : ${workflow.complete}"
    println "║  Launch dir: ${workflow.launchDir}"
    println "╚══════════════════════════════════════════════════╝"
    println ""
}

workflow.onError {
    println ""
    println "╔══════════════════════════════════════════════════╗"
    println "║            Pipeline ERROR                        ║"
    println "╠══════════════════════════════════════════════════╣"
    println "║  Error  : ${workflow.errorMessage}"
    println "║  Report : ${workflow.errorReport?.take(100)}..."
    println "╚══════════════════════════════════════════════════╝"
    println ""
}

// ─── Workflow ─────────────────────────────────────────────────────────────────

workflow {
    main:
    reads_ch = channel.fromPath("${params.input_dir}/*.txt")
        .map { file ->
            def meta = [id: file.baseName]
            [meta, file]
        }

    TRIM(reads_ch)
    MAYBE_FAIL(channel.value(params.trigger_error))

    publish:
    trimmed = TRIM.out.reads
}

output {
    trimmed { path 'trimmed' }
}

// ─────────────────────────────────────────────────────────────────────────────
// Style B: section syntax (Nextflow 25.10+ with NXF_SYNTAX_PARSER=v2)
//
// Under strict syntax the handlers move INSIDE the workflow block as labelled
// sections, alongside main: and publish:
//
// workflow {
//     main:
//     reads_ch = channel.fromPath("${params.input_dir}/*.txt")
//         .map { file ->
//             def meta = [id: file.baseName]
//             [meta, file]
//         }
//     TRIM(reads_ch)
//
//     publish:
//     trimmed = TRIM.out.reads
//
//     onComplete:
//     println "Pipeline completed: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
//     println "Duration: ${workflow.duration}"
//
//     onError:
//     println "Pipeline failed: ${workflow.errorMessage}"
// }
//
// Run with: NXF_SYNTAX_PARSER=v2 nextflow run ex4_handlers.nf
// ─────────────────────────────────────────────────────────────────────────────
