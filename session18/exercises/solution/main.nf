// ============================================================
// Session 18 SOLUTION — main.nf (strict-syntax compliant)
//
// Changes from starter_pipeline/main.nf:
//   ✓ Removed import statement
//   ✓ Removed top-level println
//   ✓ Removed top-level params.* assignments
//   ✓ Added typed params {} block
//   ✓ All Channel.* → channel.*
//   ✓ All implicit 'it' → explicit named parameters
//   ✓ workflow.onComplete → onComplete: section
//   ✓ for loop in buildSampleMap → .collectEntries {}
//   ✓ switch in getAdapterSeq → if / else if / else
// ============================================================

// ── Typed params block (new in 25.10, strict-mode only) ────
params {
    // Path to input samplesheet CSV.
    input: Path

    // Directory for published results.
    outdir: Path = 'results'

    // Reference genome identifier.
    genome: String = 'GRCh38'

    // Save intermediate files.
    save_all: Boolean = false

    // Title for the MultiQC report.
    multiqc_title: String = ''
}

// ── Includes ─────────────────────────────────────────────────
include { FASTQC     } from './modules/local/fastqc'
include { TRIM_READS } from './modules/local/trim_reads'
include { MULTIQC    } from './modules/local/multiqc'
include { SUMMARISE  } from './modules/local/summarise'

// ── Helper functions (no for/switch — strict-syntax clean) ───

// BEFORE: used a for loop. Now uses .collectEntries { }.
def buildSampleMap(rows) {
    return rows.collectEntries { row -> [row.id, row] }
}

// BEFORE: used a switch. Now uses if / else if / else.
def getAdapterSeq(String kit) {
    if (kit == 'nextera') {
        return 'CTGTCTCTTATA'
    } else if (kit == 'truseq') {
        return 'AGATCGGAAGAGC'
    } else {
        return ''
    }
}

// ── Entry workflow ────────────────────────────────────────────
workflow {

    main:

    // Build input channel — all factories are lowercase,
    // all closure parameters are explicitly named.
    if (params.input) {
        ch_input = channel.fromPath(params.input)
            .splitCsv(header: true)
            .map { row ->
                def meta = [
                    id:           row.sample,
                    strandedness: row.strandedness ?: 'auto'
                ]
                [ meta, file(row.fastq_1), file(row.fastq_2) ]
            }
    } else {
        ch_input = channel.empty()
    }

    // Explicit parameter names — no implicit 'it'
    ch_ids      = ch_input.map { meta, r1, r2 -> meta.id }
    ch_filtered = ch_input.filter { meta, r1, r2 -> meta.strandedness != 'skip' }

    // channel.value (lowercase)
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
    // Summarise metadata
    //
    SUMMARISE(ch_input.map { meta, r1, r2 -> meta })

    //
    // Collect versions
    //
    ch_versions = channel.empty()
        .mix(FASTQC.out.versions)
        .mix(TRIM_READS.out.versions)

    // ── onComplete: and onError: sections (25.10+ syntax) ───
    onComplete:
    log.info """\
        =========================================
        Pipeline completed!
        =========================================
        Workflow : ${workflow.scriptName}
        Completed: ${workflow.complete}
        Duration : ${workflow.duration}
        Success  : ${workflow.success}
        Work dir : ${workflow.workDir}
        Exit code: ${workflow.exitStatus}
        =========================================
        """.stripIndent()

    onError:
    log.error """\
        =========================================
        Pipeline FAILED
        =========================================
        Error msg: ${workflow.errorMessage}
        Work dir : ${workflow.workDir}
        =========================================
        """.stripIndent()
}
