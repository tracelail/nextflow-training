#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process ANALYZE {
    publishDir 'results/', mode: 'copy'

    input:
    tuple val(name), val(length)

    output:
    path "${name}_analysis.txt", emit: analysis

    script:
    """
    echo "Sample ${name} has ${length} characters." > "${name}_analysis.txt"
    """
}

workflow {
    samples_ch = channel.of('sampleA', 'sampleB', 'sampleC')

    tuples_ch = samples_ch.map { sample -> [sample, sample.length()]}

    ANALYZE(tuples_ch)

    ANALYZE.out.collectFile(name: 'summary.txt', storeDir: 'results/')
}