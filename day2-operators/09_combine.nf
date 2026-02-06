#!/usr/bin/env nextflow

workflow {
    // Samples
    samples_ch = channel.of('sampleA', 'sampleB')
    
    // Chromosomes
    chromosomes_ch = channel.of('chr1', 'chr2', 'chr3')
    
    // Combine them (scatter pattern)
    samples_ch
        .combine(chromosomes_ch)
        .view { sample, chr -> "Process ${sample} on ${chr}" }
}
