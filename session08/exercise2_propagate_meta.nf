/*
 * Session 8 — Exercise 2 (Intermediate)
 * Goal: Pass [meta, reads] through three chained processes.
 *       Show how meta travels with the data untouched — and how to
 *       AUGMENT it with a computed value using meta + [key: value].
 *
 * Pipeline:
 *   samplesheet.csv
 *       → PARSE_SAMPLESHEET  (channel operator, no process)
 *       → COUNT_READS         (counts lines in R1 → read_count)
 *       → AUGMENT_META        (adds read_count into meta map)
 *       → WRITE_REPORT        (writes a per-sample summary file)
 *
 * Run: nextflow run exercise2_propagate_meta.nf
 */

// ---------------------------------------------------------------------------
// Process 1: Count the number of reads in fastq_1
// ---------------------------------------------------------------------------
// KEY POINT: The process takes  tuple val(meta), path(reads)
//            and emits        tuple val(meta), path(reads), stdout
//
// 'stdout' captures whatever the script prints to standard output.
// We will use it to pass the line count back into the channel.

process COUNT_READS {

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(reads), stdout

    script:
    // Count lines in reads[0] (R1 file). FASTQ has 4 lines per read.
    // We print the number of reads (lines ÷ 4), no newline.
    // \$(...)  is a shell command substitution — the backslash escapes it
    // from Nextflow's own ${ } interpolation.
    """
    echo -n \$(( \$(wc -l < ${reads[0]}) / 4 ))
    """
}

// ---------------------------------------------------------------------------
// Process 2: Write a per-sample report file
// ---------------------------------------------------------------------------
// KEY POINT: meta now contains the read_count we added with meta + [...]
//            We access it as  ${meta.read_count}  inside the script.

process WRITE_REPORT {

    // publishDir copies output files to this folder when the process finishes
    publishDir "results/reports", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_report.txt")

    script:
    // Note: ${meta.xxx} is Nextflow variable interpolation.
    //       \$()  and  \$var  are shell — backslash keeps them as shell.
    """
    echo "=== Sample Report ===" > ${meta.id}_report.txt
    echo "ID         : ${meta.id}" >> ${meta.id}_report.txt
    echo "Condition  : ${meta.condition}" >> ${meta.id}_report.txt
    echo "Replicate  : ${meta.replicate}" >> ${meta.id}_report.txt
    echo "Strandedness: ${meta.strandedness}" >> ${meta.id}_report.txt
    echo "Read count : ${meta.read_count}" >> ${meta.id}_report.txt
    echo "R1 file    : ${reads[0]}" >> ${meta.id}_report.txt
    echo "R2 file    : ${reads[1]}" >> ${meta.id}_report.txt
    """
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

workflow {

    // --- Step 1: Parse the samplesheet into [meta, reads] tuples ---
    ch_reads = channel.fromPath("data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id          : row.sample_id,
                condition   : row.condition,
                replicate   : row.replicate,
                single_end  : row.single_end.toBoolean(),
                strandedness: row.strandedness
            ]
            def reads = [ file(row.fastq_1), file(row.fastq_2) ]
            [ meta, reads ]
        }

    // --- Step 2: Count reads — returns [meta, reads, count_as_string] ---
    ch_counted = COUNT_READS(ch_reads)

    // --- Step 3: Merge the count INTO the meta map ---
    //
    // ch_counted emits:  [ meta_map, reads_list, "8\n" ]
    //
    // We use .map to:
    //   a) trim whitespace from the stdout string  → count_str.trim()
    //   b) convert to integer                      → .toInteger()
    //   c) create a NEW meta map with the count    → meta + [read_count: ...]
    //
    // NEVER write:  meta.read_count = count        ← mutates shared object!
    // ALWAYS write: meta + [read_count: count]     ← creates new map safely

    ch_with_count = ch_counted
        .map { meta, reads, count_str ->
            def read_count = count_str.trim().toInteger()
            def new_meta = meta + [read_count: read_count]
            [ new_meta, reads ]
        }

    // View the enriched meta to confirm the count is there
    ch_with_count.view { meta, _reads ->
        "ENRICHED META: id=${meta.id}  condition=${meta.condition}  reads=${meta.read_count}"
    }

    // --- Step 4: Write reports using the enriched meta ---
    WRITE_REPORT(ch_with_count)
}

/*
 * EXPECTED OUTPUT:
 *
 *   ENRICHED META: id=CTRL_1  condition=control  reads=8
 *   ENRICHED META: id=CTRL_2  condition=control  reads=8
 *   ENRICHED META: id=CTRL_3  condition=control  reads=8
 *   ENRICHED META: id=TREAT_1  condition=treatment  reads=8
 *   ENRICHED META: id=TREAT_2  condition=treatment  reads=8
 *   ENRICHED META: id=TREAT_3  condition=treatment  reads=8
 *
 * After the run:
 *   results/reports/CTRL_1_report.txt   ← one file per sample
 *   results/reports/CTRL_2_report.txt
 *   ... (6 total)
 *
 * THINGS TO NOTICE:
 *   - meta travels through COUNT_READS completely unchanged
 *   - COUNT_READS passes it through by including val(meta) in output
 *   - meta + [read_count: n] creates a brand new map — safe in parallel
 *   - The report process accesses meta.read_count just like any other field
 */
