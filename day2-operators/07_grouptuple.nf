#!/usr/bin/env nextflow

workflow {
    // Group replicates by sample ID
    channel.of(
        ['sampleA', 'replicate1.bam'],
        ['sampleB', 'replicate1.bam'],
        ['sampleA', 'replicate2.bam'],
        ['sampleA', 'replicate3.bam'],
        ['sampleB', 'replicate2.bam']
    )
    .groupTuple()
    .view { id, files -> "Sample ${id}: ${files}" }
}
