#!/usr/bin/env nextflow

workflow {
    // Collect all numbers into one list
    channel.of(1, 2, 3, 4, 5)
        .collect()
        .view { numbers -> "All numbers: ${numbers}" }
}
