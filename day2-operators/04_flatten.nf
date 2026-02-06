#!/usr/bin/env nextflow

workflow {
    // Without flatten - the whole array is ONE item
    channel.of([1, 2, 3], [4, 5, 6])
        .view { array -> "Without flatten: ${array}" }

    // With flatten - each number is a separate item
    channel.of([1, 2, 3], [4, 5, 6])
        .flatten()
        .view { array -> "With flatten: ${array}" }
}
