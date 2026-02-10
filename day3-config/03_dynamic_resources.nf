#!/usr/bin/env nextflow

params.outdir = 'results'

process adaptiveProcess {
    label'adaptive_resources'
    tag "${sample_id} (attempt ${task.attempt})"
    errorStrategy 'retry'
    maxRetries 2

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file)

    output:
    tuple val(sample_id), path("${sample_id}_result.txt")

    script:
    """
    echo "Sample: ${sample_id}" > ${sample_id}_result.txt
    echo "Attempt: ${task.attempt}" >> ${sample_id}_result.txt
    echo "CPUs: ${task.cpus}" >> ${sample_id}_result.txt
    echo "Memory: ${task.memory}" >> ${sample_id}_result.txt
    sleep 1
    """
}

workflow {
    samples = channel.fromPath('data/sample*.txt')
        .map { file -> [file.baseName, file] }

    adaptiveProcess(samples)
}