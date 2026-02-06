#!/usr/bin/env nextflow

workflow {
    // Parse samplesheet
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, condition: row.condition]
            def reads = [file(row.fastq1), file(row.fastq2)]
            [meta, reads]
        }
        .view { meta, reads -> "After map: Meta=${meta}, Reads=${reads}" }
        // Only process control samples
        .filter { meta, reads -> meta.condition == 'control' }
        .view { meta, reads -> "After filter: Meta=${meta}, Reads=${reads}" }
        // Add processing flag
        .map { meta, reads ->
            [meta + [processed: true], reads]
        }
        .view { meta, reads -> "After adding flag: Meta=${meta}, Reads=${reads}" }
        .view { meta, reads ->
            "Will process: ${meta.id} (${meta.condition})"
        }
}
