#!/usr/bin/env nextflow

workflow {
    // Parse CSV and create [meta, [reads]] structure
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, condition: row.condition]
            def reads = [file(row.fastq1), file(row.fastq2)]
            [meta, reads]
        }
        .view { meta, reads ->
            "Meta: ${meta}, Reads: ${reads}"
        }
}
