/*
 * Session 8 — Exercise 3 (Challenge)
 * Goal: Handle missing CSV fields gracefully with null-safe operators,
 *       add conditional computed values, and use meta to drive
 *       dynamic publishDir paths.
 *
 * This exercise uses data/samplesheet_missing_fields.csv which has:
 *   - Two rows with empty 'replicate' fields
 *   - One row with an empty 'strandedness' field
 *   - One row that is single-end (no fastq_2 path)
 *
 * Run: nextflow run exercise3_null_safe.nf
 */

// ---------------------------------------------------------------------------
// Process: Write a QC summary that organises outputs by condition
// ---------------------------------------------------------------------------
// KEY POINT: publishDir uses a string that includes meta.condition
//            This means control samples go in results/control/
//            and treatment samples go in results/treatment/
//            — purely driven by the metadata, no hard-coding.

process QC_SUMMARY {

    // Dynamic path from meta — different samples publish to different folders
    publishDir "results/${meta.condition}/${meta.id}", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_qc.txt")

    script:
    // Conditional bash logic based on meta.single_end
    // If single-end, we only have one file; if paired-end, list both.
    def reads_info = meta.single_end
        ? "R1: ${reads[0]}"
        : "R1: ${reads[0]}  R2: ${reads[1]}"

    """
    echo "QC Summary for ${meta.id}" > ${meta.id}_qc.txt
    echo "Condition   : ${meta.condition}" >> ${meta.id}_qc.txt
    echo "Replicate   : ${meta.replicate}" >> ${meta.id}_qc.txt
    echo "Strandedness: ${meta.strandedness}" >> ${meta.id}_qc.txt
    echo "Single-end  : ${meta.single_end}" >> ${meta.id}_qc.txt
    echo "Paired group: ${meta.pair_group}" >> ${meta.id}_qc.txt
    echo "Reads       : ${reads_info}" >> ${meta.id}_qc.txt
    """
}

// ---------------------------------------------------------------------------
// Helper function — keeps the workflow block clean
// ---------------------------------------------------------------------------
// We extract all the CSV-parsing logic into a named function.
// The workflow just calls it with .map { row -> parseSamplesheet(row) }

def parseSamplesheet(row) {
    // --- Null-safe handling of optional fields ---
    //
    // The ?. operator (safe navigation): if row.replicate is null,
    // calling .trim() would crash. ?. returns null instead of crashing.
    //
    // The ?: operator (Elvis): if the left side is null or empty,
    // use the right side as the default value.
    //
    // Combined:  row.replicate?.trim() ?: 'unknown'
    //   Step 1: row.replicate?.trim()  → null if field is empty
    //   Step 2: ?: 'unknown'           → substitute 'unknown' for null

    def replicate    = row.replicate?.trim()    ?: 'unknown'
    def strandedness = row.strandedness?.trim() ?: 'unstranded'
    def single_end   = row.single_end?.toBoolean() ?: false

    // Build meta map with safe defaults applied
    def meta = [
        id          : row.sample_id,
        condition   : row.condition,
        replicate   : replicate,
        single_end  : single_end,
        strandedness: strandedness,
    ]

    // --- Compute a derived field from existing meta values ---
    // pair_group groups samples by condition + replicate for downstream joining
    def pair_group = "${meta.condition}_rep${meta.replicate}"
    meta = meta + [pair_group: pair_group]

    // --- Handle single-end vs paired-end reads ---
    // If fastq_2 is missing (single-end), build a 1-element list.
    // If fastq_2 is present, build a 2-element list.
    // The ?. on row.fastq_2 safely returns null if the column is empty.
    def reads = row.fastq_2?.trim()
        ? [ file(row.fastq_1), file(row.fastq_2) ]
        : [ file(row.fastq_1) ]

    return [ meta, reads ]
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

workflow {

    ch_reads = channel.fromPath("data/samplesheet_missing_fields.csv")
        .splitCsv(header: true)
        .map { row -> parseSamplesheet(row) }

    // Inspect what the channel contains — verify defaults were applied
    ch_reads.view { meta, reads ->
        "id=${meta.id}  replicate=${meta.replicate}  strand=${meta.strandedness}  " +
        "single=${meta.single_end}  pair_group=${meta.pair_group}  " +
        "n_files=${reads.size()}"
    }

    // Run QC — outputs land in condition-specific subdirectories
    QC_SUMMARY(ch_reads)
}

/*
 * EXPECTED OUTPUT from .view():
 *
 *   id=CTRL_1  replicate=1        strand=forward    single=false  pair_group=control_rep1      n_files=2
 *   id=CTRL_2  replicate=2        strand=forward    single=false  pair_group=control_rep2      n_files=2
 *   id=CTRL_3  replicate=unknown  strand=unstranded single=false  pair_group=control_repunknown  n_files=2
 *   id=TREAT_1 replicate=1        strand=reverse    single=false  pair_group=treatment_rep1    n_files=2
 *   id=TREAT_2 replicate=2        strand=reverse    single=false  pair_group=treatment_rep2    n_files=2
 *   id=TREAT_3 replicate=unknown  strand=unstranded single=true   pair_group=treatment_repunknown n_files=1
 *
 * After the run, results will be organised as:
 *   results/
 *   ├── control/
 *   │   ├── CTRL_1/CTRL_1_qc.txt
 *   │   ├── CTRL_2/CTRL_2_qc.txt
 *   │   └── CTRL_3/CTRL_3_qc.txt
 *   └── treatment/
 *       ├── TREAT_1/TREAT_1_qc.txt
 *       ├── TREAT_2/TREAT_2_qc.txt
 *       └── TREAT_3/TREAT_3_qc.txt
 *
 * THINGS TO NOTICE:
 *   - ?.  prevents NullPointerException on missing CSV fields
 *   - ?:  supplies sensible defaults so processes always get a valid value
 *   - parseSamplesheet() is a plain Groovy function — keeps workflow clean
 *   - publishDir "results/${meta.condition}/..." routes outputs automatically
 *   - Single-end samples gracefully produce a 1-element reads list
 */
