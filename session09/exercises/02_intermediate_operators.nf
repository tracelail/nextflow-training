// exercises/02_intermediate_operators.nf
// Session 9 — Exercise 2: branch, join, multiMap, collectFile
//
// Run: nextflow run exercises/02_intermediate_operators.nf

workflow {

    // ── Parse samplesheet ────────────────────────────────────────────────────
    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .map { row ->
            def meta = [id: row.sample_id, type: row.type, condition: row.condition]
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }


    // ── Part A: branch ───────────────────────────────────────────────────────
    // branch routes each item to the FIRST label whose condition is true.
    //
    // CRITICAL: the catch-all `true` at the end is REQUIRED.
    // Without it, items matching no condition are silently dropped with no error.

    ch_samples
        .branch { meta, _fq1, _fq2 ->
            tumor:  meta.type == 'tumor'
            normal: true           // catch-all — captures everything else
        }
        .set { ch_split } // can also do ch_split = ch_samples.branch{...}

    ch_split.tumor
        .view { meta, _fq1, _fq2 -> "TUMOR:  ${meta.id}" }

    ch_split.normal
        .view { meta, _fq1, _fq2 -> "NORMAL: ${meta.id}" }


    // ── Part B: join ─────────────────────────────────────────────────────────
    // join performs an INNER join by default:
    //   - only items whose key exists in BOTH channels are emitted
    //   - unmatched items are silently dropped (or error under strict mode)
    //
    // Use remainder: true for an OUTER join — unmatched items appear with null.

    ch_scores = channel.of(
        [ [id: 'SAMPLE_A'], 42 ],
        [ [id: 'SAMPLE_B'], 87 ],
        [ [id: 'SAMPLE_C'], 61 ]
    )

    ch_flags = channel.of(
        [ [id: 'SAMPLE_A'], 'PASS' ],
        [ [id: 'SAMPLE_B'], 'FAIL' ],
        [ [id: 'SAMPLE_D'], 'PASS' ]   // SAMPLE_D has no matching score
    )

    // Inner join: SAMPLE_C (no flag) and SAMPLE_D (no score) are dropped
    ch_scores
        .join( ch_flags )
        .view { meta, score, flag -> "Inner:  ${meta.id} score=${score} flag=${flag}" }

    // Outer join: all items appear; unmatched fields are null
    ch_scores
        .join( ch_flags, remainder: true )
        .view { meta, score, flag -> "Outer:  ${meta.id} score=${score} flag=${flag}" }


    // ── Part C: multiMap ─────────────────────────────────────────────────────
    // multiMap sends EVERY item to ALL labeled outputs.
    // Unlike branch (one output per item), multiMap copies each item to every label.
    // Use it to split one channel into several parallel downstream paths.

    ch_samples
        .multiMap { meta, fq1, fq2 ->
            meta_only: meta
            reads:     [ meta.id, fq1, fq2 ]
        }
        .set { ch_multi }

    ch_multi.meta_only
        .view { meta -> "Multi_Meta_only:  ${meta.id} (${meta.type})" }

    ch_multi.reads
        .view { id, _fq1, _fq2 -> "Multi_Reads: ${id}" }


    // ── Part D: collectFile ──────────────────────────────────────────────────
    // collectFile collects channel strings/values and writes them to a file.
    // storeDir persists the output file after the workflow completes.
    // Without storeDir, the file is placed in a temp dir and deleted on exit.

    ch_samples
        .map { meta, _fq1, _fq2 -> "${meta.id}\t${meta.type}\t${meta.condition}\n" }
        .collectFile( name: 'sample_summary.tsv', storeDir: 'results' )
        .view { f -> "Written: ${f}" }

}
