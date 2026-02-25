/*
 * Session 8 — Exercise 1 (Basic)
 * Goal: Parse a CSV samplesheet into [meta, [fastq1, fastq2]] tuples
 *       and inspect what the channel contains at each step.
 *
 * Run: nextflow run exercise1_parse_csv.nf
 */

// ---------------------------------------------------------------------------
// Step A: Look at the raw CSV rows BEFORE any transformation
// ---------------------------------------------------------------------------
workflow {

    // 1. Read the samplesheet file and split it on commas, using the header
    //    row as keys. Each row becomes a Groovy map.
    ch_raw = channel.fromPath("data/samplesheet.csv")
        .splitCsv(header: true)

    // View the raw rows so you can see what splitCsv gives us
    ch_raw.view { row -> "RAW ROW: ${row}" }

    // ---------------------------------------------------------------------------
    // Step B: Transform each row into a [meta, reads] tuple
    // ---------------------------------------------------------------------------

    // The .map operator runs a closure once per item in the channel.
    // { row -> ... } is the closure. 'row' is the name we give each item.
    // We build two things:
    //   1. A 'meta' map containing only the metadata fields
    //   2. A list of the two read files
    //
    // IMPORTANT: row.fastq_1 and row.fastq_2 are plain strings coming from
    //            the CSV. We must wrap them with file() to make Nextflow
    //            treat them as file paths (not just text).

    ch_reads = channel.fromPath("data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            // Build the metadata map — only the metadata columns go here
            def meta = [
                id          : row.sample_id,
                condition   : row.condition,
                replicate   : row.replicate,
                single_end  : row.single_end.toBoolean(),
                strandedness: row.strandedness
            ]

            // Build the reads list — file() converts strings into Path objects
            def reads = [ file(row.fastq_1), file(row.fastq_2) ]

            // Return the tuple: [meta_map, reads_list]
            // This is the standard nf-core convention
            [ meta, reads ]
        }

    // View the transformed channel
    ch_reads.view { meta, reads ->
        """
        SAMPLE  : ${meta.id}
        CONDITON: ${meta.condition}  REP: ${meta.replicate}
        READS   : ${reads[0].name}  /  ${reads[1].name}
        """
    }
}

/*
 * EXPECTED OUTPUT (order may vary — channels are parallel):
 *
 *   RAW ROW: [sample_id:CTRL_1, condition:control, replicate:1, ...]
 *   RAW ROW: [sample_id:CTRL_2, ...]
 *   ... (6 rows total)
 *
 *   SAMPLE  : CTRL_1
 *   CONDITON: control  REP: 1
 *   READS   : CTRL_1_R1.fastq  /  CTRL_1_R2.fastq
 *   ... (6 samples total)
 *
 * THINGS TO NOTICE:
 *   - splitCsv(header:true) gives you a map per row — no index numbers
 *   - .map { row -> ... } lets you reshape each item freely
 *   - The meta map holds only metadata; the reads list holds only file paths
 *   - file() wraps the string so Nextflow can stage it into the work dir
 */
