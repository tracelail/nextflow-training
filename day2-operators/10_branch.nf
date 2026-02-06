#!/usr/bin/env nextflow

workflow {
    // Create samples wsampleh different depths
    samples = channel.of(
        [id: 'sample1', depth: 15000000],
        [id: 'sample2', depth: 35000000],
        [id: 'sample3', depth: 8000000],
        [id: 'sample4', depth: 42000000]
    )

    // Branch by sequencing depth
    samples
        .branch { sample ->
            high: sample.depth >= 30000000
            medium: sample.depth >= 10000000
            low: true  // catch-all
        }
        .set { result }

    result.high.view { sample -> "HIGH coverage: ${sample.id} (${sample.depth})" }
    result.medium.view { sample ->"MEDIUM coverage: ${sample.id} (${sample.depth})" }
    result.low.view { sample -> "LOW coverage: ${sample.id} (${sample.depth})" }
}
