// solutions/02_intermediate_operators_solution.nf
// Session 9 — Exercise 2 SOLUTION

workflow {

    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .map { row ->
            def meta = [id: row.sample_id, type: row.type, condition: row.condition]
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }

    // Part A: branch with required catch-all
    ch_samples
        .branch { meta, fq1, fq2 ->
            tumor:  meta.type == 'tumor'
            normal: true
        }
        .set { ch_split }

    ch_split.tumor.view  { meta, fq1, fq2 -> "TUMOR:  ${meta.id}" }
    ch_split.normal.view { meta, fq1, fq2 -> "NORMAL: ${meta.id}" }

    // Part B: inner and outer join
    ch_scores = channel.of(
        [ [id: 'SAMPLE_A'], 42 ],
        [ [id: 'SAMPLE_B'], 87 ],
        [ [id: 'SAMPLE_C'], 61 ]
    )
    ch_flags = channel.of(
        [ [id: 'SAMPLE_A'], 'PASS' ],
        [ [id: 'SAMPLE_B'], 'FAIL' ],
        [ [id: 'SAMPLE_D'], 'PASS' ]
    )

    ch_scores.join( ch_flags )
        .view { meta, score, flag -> "Inner:  ${meta.id} score=${score} flag=${flag}" }

    ch_scores.join( ch_flags, remainder: true )
        .view { meta, score, flag -> "Outer:  ${meta.id} score=${score} flag=${flag}" }

    // Part C: multiMap — every item goes to BOTH outputs
    ch_samples
        .multiMap { meta, fq1, fq2 ->
            meta_only: meta
            reads:     [ meta.id, fq1, fq2 ]
        }
        .set { ch_multi }

    ch_multi.meta_only.view { meta -> "Meta:  ${meta.id} (${meta.type})" }
    ch_multi.reads.view     { id, fq1, fq2 -> "Reads: ${id}" }

    // Part D: collectFile — write TSV summary
    ch_samples
        .map { meta, fq1, fq2 -> "${meta.id}\t${meta.type}\t${meta.condition}\n" }
        .collectFile( name: 'sample_summary.tsv', storeDir: 'results' )
        .view { f -> "Written: ${f}" }

}
