#!/usr/bin/env nextflow

workflow {
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .view { row -> 
            "Sample: ${row.sample_id}, R1: ${row.fastq1}, R2: ${row.fastq2}, Condition: ${row.condition}"
        }
}
