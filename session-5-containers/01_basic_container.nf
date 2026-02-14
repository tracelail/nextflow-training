#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Session 5 Exercise 1: Basic Container Usage
 *
 * This workflow demonstrates running a process inside a container.
 * FastQC runs without being installed on your system!
 */

process FASTQC_BASIC {
    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir 'results/fastqc', mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path("${sample_id}_fastqc.html")
    path("${sample_id}_fastqc.zip")

    script:
    """


    # Run FastQC (this command runs INSIDE the container)
    # FastQC will automatically name outputs based on input filename
    fastqc ${reads}
    """
}

workflow {
    // Create a channel with a sample
    samples_ch = channel.of(
        ['sample1', file('data/sample1.fastq')]
    )

    // Run the containerized process
    FASTQC_BASIC(samples_ch)

    workflow.onComplete {
        println "Pipeline completed!"
        println "Check results in: results/fastqc/"
        println "Container used: biocontainers/fastqc:v0.11.9_cv8"
    }
}

