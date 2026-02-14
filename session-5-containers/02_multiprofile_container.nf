#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Session 5 Exercise 2: Multi-Profile Container Configuration
 *
 * This workflow demonstrates:
 * - Multiple containerized processes
 * - Different containers for different tools
 * - Profile-based configuration (Docker vs Singularity)
 */

process SEQTK_SAMPLE {
    tag "$sample_id"
    container 'biocontainers/seqtk:v1.3-1-deb_cv1'

    input:
    tuple val(sample_id), path(reads)
    val(num_reads)

    output:
    tuple val(sample_id), path("${sample_id}_sampled.fastq"), emit: reads // available as `SEQTK_SAMPLE.out.reads`

    script:
    """
    seqtk sample -s 100 ${reads} ${num_reads} > ${sample_id}_sampled.fastq
    """
}

process FASTQC {
    tag "$sample_id"
    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir 'results/qc', mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*_fastqc.{html,zip}"), emit: reports

    script:
    """
    fastqc -q ${reads}
    """
}

process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0'

    publishDir 'results/multiqc', mode: 'copy'

    input:
    path(fastqc_files)

    output:
    path("multiqc_report.html")
    path("multiqc_data")

    script:
    """
    multiqc .
    """
}

workflow {
    // Create channel with multiple samples
    samples_ch = channel.fromPath('data/*.fastq')
        .map { file ->
            def sample_id = file.baseName
            [sample_id, file]
        }

    // Subsample reads to 50 reads each
    SEQTK_SAMPLE(samples_ch, 50)

    // Run quality control on subsampled reads
    FASTQC(SEQTK_SAMPLE.out.reads)

    // Aggregate all reports with MultiQC
    MULTIQC(
        FASTQC.out.reports                      // this is a tuple and only need the files
            .map { sample_id, files -> files }  // extracts just the files
            .collect()                          // gathers all the files to one list
    )

    // Event handler using the onComplete: directive syntax
    workflow.onComplete = {
        println "Pipeline completed at: ${workflow.complete}"
        println "Success: ${workflow.success}"
    }

    workflow.onError = {
        println "Error: ${workflow.errorMessage}"
    }
}
