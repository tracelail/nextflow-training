// exercises/01_basic_operators.nf
// Session 9 — Exercise 1: map, filter, flatten, collect
//
// Run: nextflow run exercises/01_basic_operators.nf
//
// 2026 syntax rules enforced:
//   - lowercase channel.of() and channel.fromPath()
//   - explicit closure parameters (no implicit `it`)

workflow {

    // ── Part A: map ──────────────────────────────────────────────────────────
    // map transforms each item one-at-a-time.
    // The closure receives one item and must return one item.
    // Always name the closure parameter explicitly.

    ch_numbers = channel.of( 1, 2, 3, 4, 5 )

    ch_numbers
        .map { n -> n * n }
        .view { n -> "Squared: ${n}" }

    // map on a file channel — attach the base name as a label
    ch_files = channel.fromPath( 'data/*.txt' )

    ch_files
        .map { f -> [f.baseName, f] }
        .view { name, _f -> "File: ${name}" }


    // ── Part B: filter ───────────────────────────────────────────────────────
    // filter keeps only items where the closure returns true.
    // Items returning false are discarded permanently.

    channel.of( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 )
        .filter { n -> n % 2 == 0 }
        .view { n -> "Even: ${n}" }


    // ── Part C: flatten ──────────────────────────────────────────────────────
    // flatten recursively unpacks nested lists.
    // [1, 2], [3, [4, 5]], 6  →  1, 2, 3, 4, 5, 6

    channel.of( [1, 2], [3, [4, 5]], 6 )
        .flatten()
        .view { n -> "Flattened: ${n}" }


    // ── Part D: collect ──────────────────────────────────────────────────────
    // collect waits for ALL items then emits ONE list as a value channel.
    // Value channels are reusable — they can be read unlimited times.

    channel.of( 'alpha', 'beta', 'gamma', 'delta' )
        .collect()
        .view { list -> "All words: ${list}" }

    // ── TODO Exercise Steps ───────────────────────────────────────────────────
    // After running as-is:
    //
    // Step 3: Add Part E below — parse data/samplesheet.csv with splitCsv
    //   and map each row into a [meta, file, file] tuple. View the sample ID.
    //
    // Step 4: Chain a .filter after your .map to keep only tumor samples.
    //   You should see only 3 lines instead of 6.

    // ── Part E: Parse samplesheet.csv ──────────────────────────────────────────────────────

    channel.fromPath('data/samplesheet.csv')
        .splitCsv(header: true)
        .view{ csv -> "Split csv: ${csv}"}
        .map { row ->
            def meta = [
                id: row.id,
                type: row.type,
                condition: row.condition
            ]
            [meta, file(row.fastq_1), file(row.fastq_2)]
        }
        .view { meta, fq1, fq2 -> "\n Parsed samplesheet\n Meta: ${meta}, fastq1: ${fq1}, fastq2: ${fq2}"}
        .filter{ meta, _fq1, _fq2 -> meta.type == 'tumor'}
        .view { meta, fq1, fq2 -> "\n Parsed filtered samplesheet\n Meta: ${meta}, fastq1: ${fq1}, fastq2: ${fq2}"}

}
