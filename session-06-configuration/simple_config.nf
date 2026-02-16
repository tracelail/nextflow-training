#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// Default parameters
params.greeting = "Hello"
params.name = "World"
params.repetitions = 3
params.outdir = "results"

process GREET {
    publishDir params.outdir, mode: 'copy'

    output:
    path "greeting.txt"

    script:
    """
    for i in \$(seq 1 ${params.repetitions}); do
        echo "${params.greeting}, ${params.name}!"
    done > greeting.txt
    """
}

workflow {
    GREET().view { file -> "Greeting file created: ${file}" }
}
