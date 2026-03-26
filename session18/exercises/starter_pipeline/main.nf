#!/usr/bin/env nextflow
// ============================================================
// Session 18 Starter Pipeline — main.nf
//
// This file deliberately contains EVERY category of strict-syntax
// issue you will encounter in real pipelines. Your job is to:
//   1. Run `nextflow lint main.nf` and read the output
//   2. Fix each category following the README instructions
//   3. Verify with `nextflow lint .` until no warnings remain
//   4. Add the typed params block and workflow sections
//
// DO NOT run NXF_SYNTAX_PARSER=v2 until Exercise 3.
// ============================================================

// ── VIOLATION #1: import statement ─────────────────────────
// Strict syntax bans import declarations entirely.
// Fix: use fully qualified names (groovy.json.JsonSlurper)

// ── VIOLATION #2: top-level executable statement ───────────
// Executable statements (println, variable assignments) cannot
// appear at the top level alongside declarations.
// Fix: move into a workflow block or delete if not needed.

// ── VIOLATION #3: channel (uppercase) factory ──────────────
// All channel factories must be lowercase.
// Fix: channel.of → channel.of  etc.
// params.input       = null
// params.outdir      = 'results'
// params.genome      = 'GRCh38'
// params.save_all    = false
// params.multiqc_title = ''

// Pipeline params now listed in the main.nf
params {
    input: Path // no default so the path is required

    // Optional params with default
    outdir:         Path    = 'results'
    genome:         String  = 'GRCh38'
    save_all:       Boolean = false
    multiqc_title:  String   = ''

}

// ============================================================
// INCLUDES
// ============================================================

include { FASTQC        } from './modules/local/fastqc'
include { TRIM_READS    } from './modules/local/trim_reads'
include { MULTIQC       } from './modules/local/multiqc'
include { SUMMARISE     } from './modules/local/summarise'

// ============================================================
// HELPER FUNCTION — contains a for-loop (strict bans these)
// ============================================================

// ── VIOLATION #4: for loop ─────────────────────────────────
// Fix: replace with .collect { } functional style
// def buildSampleMap(rows) {
//     def result = [:]
//     for (row in rows) {
//         result[row.id] = row
//     }
//     return result
// }
def buildSampleMap(rows) {
    return rows.collectEntries { row -> [row.id, row] }
}

// ── VIOLATION #5: switch statement ─────────────────────────
// Fix: replace with if / else if / else
def getAdapterSeq(String kit) {
    // switch (kit) {
    //     case 'nextera': return 'CTGTCTCTTATA'
    //     case 'truseq':  return 'AGATCGGAAGAGC'
    //     default:        return ''
    // }
    if (kit == 'nextera') {
        'CTGTCTCTTATA'
    } else if (kit == 'truseq') {
        'AGATCGGAAGAGC'
    } else {
        ''
    }
}

// ============================================================
// MAIN WORKFLOW
// ============================================================

workflow {
    main:

    println "Starting pipeline: ${workflow.scriptName}"


    // ── VIOLATION #6: uppercase channel factories ──────────
    // Fix: channel.fromPath, channel.empty, channel.value
    if (params.input) {
        ch_input = channel.fromPath(params.input)
            .splitCsv(header: true)
            .map { it ->
                // ── VIOLATION #7: explicit 'it ->' is fine,
                //    but closures using bare 'it' without '->'
                //    are deprecated. Check the implicit uses below.
                def meta = [
                    id:        it.sample,
                    strandedness: it.strandedness ?: 'auto'
                ]
                [ meta, file(it.fastq_1), file(it.fastq_2) ]
            }
    } else {
        ch_input = channel.empty()
    }

    // ── VIOLATION #8: implicit 'it' in closure (no arrow) ──
    // The line below uses { it } without declaring a parameter.
    // Fix: { v -> v }  or  { sample -> sample }
    ch_ids = ch_input.map { meta, _r1, _r2 -> meta.id }

    // ── VIOLATION #9: another implicit 'it' ────────────────
    ch_filtered = ch_input.filter { meta, _r1, _r2 -> meta.strandedness != 'skip' }

    // ── VIOLATION #10: uppercase channel.value ─────────────
    ch_genome = channel.value(params.genome)

    //
    // Run QC and trimming
    //
    FASTQC(ch_input)
    TRIM_READS(ch_input, ch_genome)
    MULTIQC(
        FASTQC.out.zip.collect(),
        TRIM_READS.out.log.collect()
    )

    //
    // Summarise using a helper function with a for-loop internally
    //
    SUMMARISE(ch_input.map { meta, _r1, _r2 -> meta })

    //
    // Emit versions channel
    //
    // ch_versions = channel.empty().mix(FASTQC.out.versions).mix(TRIM_READS.out.versions)
    // ch_versions = channel.empty()
    //     .mix(FASTQC.out.versions)
    //     .mix(TRIM_READS.out.versions)

    // ── VIOLATION #11: top-level onComplete handler ────────────
    // workflow.onComplete at the top level is banned in strict mode
    // because it mixes a statement with declarations.
    // Fix: move inside the workflow block as an onComplete: section.

    // onComplete:
    // log.info """\
    //     =========================================
    //     Pipeline completed!
    //     =========================================
    //     Workflow : ${workflow.scriptName}
    //     Completed: ${workflow.complete}
    //     Duration : ${workflow.duration}
    //     Success  : ${workflow.success}
    //     Work dir : ${workflow.workDir}
    //     Exit code: ${workflow.exitStatus}
    //     =========================================
    //     """.stripIndent()

    // onError:
    // log.error """\
    //     =========================================
    //     Pipeline FAILED
    //     =========================================
    //     Error msg: ${workflow.errorMessage}
    //     Work dir : ${workflow.workDir}
    //     =========================================
    //     """.stripIndent()
}

