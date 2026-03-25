#!/usr/bin/env nextflow

// =============================================================================
// Session 16 test pipeline
// Demonstrates using the SEQTK_SEQ local module.
// Run: nextflow run main.nf -profile conda
// =============================================================================

include { SEQTK_SEQ } from './modules/local/seqtk/seq/main.nf'

workflow {

    // ------------------------------------------------------------------
    // Build the input channel from the samplesheet CSV.
    // Each row becomes a [meta, reads_file] tuple.
    // ------------------------------------------------------------------
    ch_reads = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            // meta map holds all per-sample metadata.  id is the minimum required key.
            def meta  = [ id: row.sample, single_end: true ]
            // file() turns the CSV string path into a Nextflow Path object.
            def reads = file(row.fastq, checkIfExists: true)
            [ meta, reads ]
        }

    // ------------------------------------------------------------------
    // Run the module.  SEQTK_SEQ converts FASTQ → FASTA.
    // ------------------------------------------------------------------
    SEQTK_SEQ(ch_reads)

    // ------------------------------------------------------------------
    // View the outputs.  The .fasta channel emits [meta, path] tuples.
    // ------------------------------------------------------------------
    SEQTK_SEQ.out.fasta.view { meta, fasta ->
        "✓ ${meta.id}: ${fasta.name}"
    }

    // ------------------------------------------------------------------
    // The topic channel is handled automatically by Nextflow — you do not
    // need to collect or pass it anywhere.  Pipelines built on the nf-core
    // template collect it with channel.topic("versions").
    // ------------------------------------------------------------------
}
