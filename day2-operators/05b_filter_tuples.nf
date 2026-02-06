#!/usr/bin/env nextflow

workflow {
    // Create sample tuples with metadata
    channel.of(
        [id: 'sample1', type: 'tumor'],
        [id: 'sample2', type: 'normal'],
        [id: 'sample3', type: 'tumor'],
        [id: 'sample4', type: 'normal']
    )
    .filter { meta -> meta.type == 'tumor' }
    .view { meta -> "Tumor sample: ${meta.id}" }
}