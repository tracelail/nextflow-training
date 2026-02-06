#!/usr/bin/env nextflow

workflow {
    channel.of(
        ['patient1', 'tumor', 'file1.bam'],
        ['patient1', 'normal', 'file2.bam'],
        ['patient2', 'tumor', 'file3.bam'],
        ['patient1', 'tumor', 'file4.bam'],
        ['patient2', 'normal', 'file5.bam']
    )
    // Filter for tumor samples only
    .filter { id, type, file -> type == 'tumor' }
    // Keep only [id, file] for grouping
    .map { id, type, file -> [id, file] }
    // Group by patient ID
    .groupTuple()
    .view()
}
