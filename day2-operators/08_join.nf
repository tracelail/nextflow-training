#!/usr/bin/env nextflow

workflow {
    // Create two channels with matching keys
    reads_ch = channel.of(
        ['sample1', 'reads.fq'],
        ['sample2', 'reads.fq'],
        ['sample3', 'reads.fq']
    )
    
    reference_ch = channel.of(
        ['sample1', 'ref.fa'],
        ['sample2', 'ref.fa'],
        ['sample3', 'ref.fa']
    )
    
    // Join them
    reads_ch
        .join(reference_ch)
        .view { id, reads, ref -> "Sample ${id}: ${reads} + ${ref}" }
}
