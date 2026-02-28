// solutions/01_basic_operators_solution.nf
// Session 9 — Exercise 1 SOLUTION (complete, including Steps 3 and 4)

workflow {

    // Part A: map — square each number
    ch_numbers = channel.of( 1, 2, 3, 4, 5 )

    ch_numbers
        .map { n -> n * n }
        .view { n -> "Squared: ${n}" }

    // map on a file channel
    channel.fromPath( 'data/*.txt' )
        .map { f -> [f.baseName, f] }
        .view { name, f -> "File: ${name}" }

    // Part B: filter — even numbers only
    channel.of( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 )
        .filter { n -> n % 2 == 0 }
        .view { n -> "Even: ${n}" }

    // Part C: flatten — unpack nested lists
    channel.of( [1, 2], [3, [4, 5]], 6 )
        .flatten()
        .view { n -> "Flattened: ${n}" }

    // Part D: collect — bundle all into one list
    channel.of( 'alpha', 'beta', 'gamma', 'delta' )
        .collect()
        .view { list -> "All words: ${list}" }

    // Part E (Step 3): Parse samplesheet into [meta, file, file] tuples
    channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .map { row ->
            def meta = [
                id:   row.sample_id,
                type: row.type
            ]
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }
        // Step 4: filter to tumor samples only
        .filter { meta, fq1, fq2 -> meta.type == 'tumor' }
        .view { meta, fq1, fq2 -> "Sample: ${meta.id} (${meta.type})" }

}
