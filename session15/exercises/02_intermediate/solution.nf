#!/usr/bin/env nextflow

/*
    exercises/02_intermediate/solution.nf — DO NOT PEEK until you've tried!
*/

include { FASTQC  } from '../../modules/nf-core/fastqc/main'
include { MULTIQC } from '../../modules/nf-core/multiqc/main'

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

    ch_multiqc_files = FASTQC.out.zip
        .map { meta, zips -> zips }
        .collect()

    MULTIQC(
        ch_multiqc_files,
        [],
        [],
        [],
        [],
        []
    )

    MULTIQC.out.report.view { report -> "MultiQC report: ${report}" }

}
