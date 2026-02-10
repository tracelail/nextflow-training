#!/usr/bin/env nextflow

// Parameters
params.outdir = 'results'

process challenge_process {
    label 'process_low'
    tag "sample: ${sample_id}, attempt: ${task.attempt}"

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file)

    output:
    tuple val(sample_id), path("${sample_id}_challenge.txt")

    script:
    """
    echo sample: ${sample_id} > ${sample_id}_challenge.txt
    echo attempt: ${task.attempt} >> ${sample_id}_challenge.txt
    echo cpus: ${task.cpus} >> ${sample_id}_challenge.txt
    echo memory: ${task.memory} >> ${sample_id}_challenge.txt
    """

}

workflow {
    samples = channel.fromPath('data/sample*.txt')
        .map {file -> [file.baseName, file]}

    challenge_process(samples)
}