#!/usr/bin/env nextflow

/*
    exercises/01_basic/solution.nf — DO NOT PEEK until you've tried!
*/

include { FASTQC } from '../../modules/nf-core/fastqc/main'

workflow {

    ch_reads = channel
        .fromPath('../../assets/samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta  = [ id: row.sample, single_end: false ]
            def reads = [ file(row.fastq_1), file(row.fastq_2) ]
            [ meta, reads ]
        }

    FASTQC(ch_reads)

    FASTQC.out.html.view { meta, html -> "Sample: ${meta.id} → ${html}" }

}
