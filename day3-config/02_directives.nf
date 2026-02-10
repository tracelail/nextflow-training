#!/usr/bin/env nextflow

params.outdir = 'results'

process taggedProcess {
    label 'process_low'
    tag "Processing ${sample_id}" // tagging makes logs human readable to tell which task fails
    cpus 2              // Typically defined in nextflow.config and config will take precedence
    memory '500.MB'     // Typically defined in nextflow.config and config will take precedence

    // publishDir creates directory
    publishDir "${params.outdir}/${sample_id}", mode: 'copy' // copies the output files from the work directory to the params.outdir

    input:
    tuple val(sample_id), path(input_file)

    output:
    tuple val(sample_id), path("${sample_id}_processed.txt")

    script:
    """
    echo "Sample: ${sample_id}" > ${sample_id}_processed.txt
    echo "Using ${task.cpus} CPUs" >> ${sample_id}_processed.txt
    echo "Memory: ${task.memory}" >> ${sample_id}_processed.txt
    cat ${input_file} >> ${sample_id}_processed.txt
    """
}

workflow {
    samples = channel.fromPath('data/sample*.txt')
        .map { file -> [file.baseName, file] }  // creates tuple for inputs of taggedProcess

    taggedProcess(samples)
}