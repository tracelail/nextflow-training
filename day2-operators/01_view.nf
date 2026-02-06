#!/usr/bin/env nextflow

workflow {
    // Create a simple channel
    channel.of('apple', 'banana', 'cherry')
        .view { fruit -> "I found a: ${fruit}"}
}
