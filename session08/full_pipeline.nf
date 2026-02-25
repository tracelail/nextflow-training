/*
 * Session 8 — Full Pipeline Demo
 * -----------------------------------------------------------------------
 * This file ties every Session 8 concept together in one pipeline:
 *
 *   1. Parse samplesheet → [meta, reads] with null-safe defaults
 *   2. COUNT_READS    → count reads in R1, augment meta with read_count
 *   3. ASSESS_QUALITY → assign quality_tier based on read_count, augment meta
 *   4. FINAL_REPORT   → write per-sample report, publish under condition/tier
 *
 * Run: nextflow run full_pipeline.nf
 *
 * After running you should see:
 *   results/
 *   ├── control/
 *   │   └── standard/    ← or 'high' if read_count > threshold
 *   │       ├── CTRL_1_final_report.txt
 *   │       ├── CTRL_2_final_report.txt
 *   │       └── CTRL_3_final_report.txt
 *   └── treatment/
 *       └── standard/
 *           ├── TREAT_1_final_report.txt
 *           ├── TREAT_2_final_report.txt
 *           └── TREAT_3_final_report.txt
 */

// ---------------------------------------------------------------------------
// Process 1: Count reads in R1
// ---------------------------------------------------------------------------
// Passes meta unchanged; appends stdout (read count) as third tuple element.

process COUNT_READS {

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(reads), stdout

    script:
    """
    echo -n \$(( \$(wc -l < ${reads[0]}) / 4 ))
    """
}

// ---------------------------------------------------------------------------
// Process 2: Assess quality tier
// ---------------------------------------------------------------------------
// Receives [meta_with_read_count, reads].
// Writes a small file recording the tier, emits it so the next
// process knows it ran (even though we don't use the file's content).

process ASSESS_QUALITY {

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(reads), path("${meta.id}_tier.txt")

    script:
    """
    echo "${meta.quality_tier}" > ${meta.id}_tier.txt
    """
}

// ---------------------------------------------------------------------------
// Process 3: Write the final report
// ---------------------------------------------------------------------------
// publishDir is driven entirely by meta fields — no hard-coded paths.

process FINAL_REPORT {

    publishDir "results/${meta.condition}/${meta.quality_tier}", mode: 'copy'

    input:
    tuple val(meta), path(reads), path(tier_file)

    output:
    tuple val(meta), path("${meta.id}_final_report.txt")

    script:
    """
    echo "==========================================" > ${meta.id}_final_report.txt
    echo " Final Report: ${meta.id}"                >> ${meta.id}_final_report.txt
    echo "==========================================" >> ${meta.id}_final_report.txt
    echo "Condition    : ${meta.condition}"          >> ${meta.id}_final_report.txt
    echo "Replicate    : ${meta.replicate}"          >> ${meta.id}_final_report.txt
    echo "Strandedness : ${meta.strandedness}"       >> ${meta.id}_final_report.txt
    echo "Single-end   : ${meta.single_end}"         >> ${meta.id}_final_report.txt
    echo "Read count   : ${meta.read_count}"         >> ${meta.id}_final_report.txt
    echo "Quality tier : ${meta.quality_tier}"       >> ${meta.id}_final_report.txt
    """
}

// ---------------------------------------------------------------------------
// Helper: parse a samplesheet row into [meta, reads]
// ---------------------------------------------------------------------------

def parseSamplesheet(row) {
    def replicate    = row.replicate?.trim()    ?: 'unknown'
    def strandedness = row.strandedness?.trim() ?: 'unstranded'
    def single_end   = row.single_end?.toBoolean() ?: false

    def meta = [
        id          : row.sample_id,
        condition   : row.condition,
        replicate   : replicate,
        single_end  : single_end,
        strandedness: strandedness
    ]

    def reads = row.fastq_2?.trim()
        ? [ file(row.fastq_1), file(row.fastq_2) ]
        : [ file(row.fastq_1) ]

    return [ meta, reads ]
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

workflow {

    // Step 1 — parse samplesheet
    ch_reads = channel.fromPath("data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row -> parseSamplesheet(row) }

    // Step 2 — count reads, then merge count into meta
    ch_counted = COUNT_READS(ch_reads)
        .map { meta, reads, count_str ->
            def read_count = count_str.trim().toInteger()
            [ meta + [read_count: read_count], reads ]
        }

    // Step 3 — assign quality tier based on read count, merge into meta
    //   > 20 reads → 'high'
    //   5–20 reads → 'standard'
    //   < 5 reads  → 'low'
    ch_tiered = ch_counted
        .map { meta, reads ->
            def tier = meta.read_count > 20 ? 'high'
                     : meta.read_count > 5 ? 'standard'
                     : 'low'
            [ meta + [quality_tier: tier], reads ]
        }

    // Step 4 — assess quality (process that records tier to a file)
    ch_assessed = ASSESS_QUALITY(ch_tiered)

    // Step 5 — write final reports, published under condition/tier
    ch_reports = FINAL_REPORT(ch_assessed)

    // Confirm all samples completed with a summary view
    ch_reports.view { meta, report ->
        "DONE: ${report.name}  [${meta.condition} / ${meta.quality_tier} / ${meta.read_count} reads]"
    }
}

/*
 * EXPECTED CONSOLE OUTPUT (order may vary):
 *
 *   DONE: CTRL_1_final_report.txt  [control / standard / 8 reads]
 *   DONE: CTRL_2_final_report.txt  [control / standard / 8 reads]
 *   DONE: CTRL_3_final_report.txt  [control / standard / 8 reads]
 *   DONE: TREAT_1_final_report.txt [treatment / standard / 8 reads]
 *   DONE: TREAT_2_final_report.txt [treatment / standard / 8 reads]
 *   DONE: TREAT_3_final_report.txt [treatment / standard / 8 reads]
 *
 * The synthetic FASTQ files each have 8 reads → tier='standard'.
 * To test 'high' tier: edit data/samplesheet.csv to point to a
 * FASTQ file with > 20 reads and re-run with -resume.
 */
