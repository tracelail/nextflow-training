#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.input = "data/samples.csv"
params.outdir = "results"

process ANALYZE {
    label 'process_low'
    container 'ubuntu:22.04'
    publishDir params.outdir, mode: 'copy'
    
    input:
    val sample_name
    
    output:
    path "${sample_name}_report.txt"
    
    script:
    """
    echo "Analyzing ${sample_name}" > ${sample_name}_report.txt
    echo "Memory: ${task.memory}" >> ${sample_name}_report.txt
    echo "CPUs: ${task.cpus}" >> ${sample_name}_report.txt
    echo "Container: ${task.container}" >> ${sample_name}_report.txt
    sleep 2
    echo "Analysis complete" >> ${sample_name}_report.txt
    """
}

process SUMMARIZE {
    label 'process_medium'
    container 'ubuntu:22.04'
    publishDir params.outdir, mode: 'copy'
    
    input:
    path reports
    
    output:
    path "summary.txt"
    
    script:
    """
    echo "Summary Report" > summary.txt
    echo "=============" >> summary.txt
    cat ${reports} >> summary.txt
    """
}

workflow {
    // Create sample channel
    samples_ch = channel.of('sample1', 'sample2', 'sample3')
    
    // Analyze each sample
    ANALYZE(samples_ch)
    
    // Collect and summarize
    SUMMARIZE(ANALYZE.out.collect())
}
