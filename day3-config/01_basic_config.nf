#!/usr/bin/env nextflow

// Default parameter
params.input_pattern = 'data/*.txt'

process analyzeFile {
    input:
    tuple val(sample_id), path(input_file)

    output:
    path "${sample_id}_analysis.txt"

    script:
    """
    echo "Analyzing ${sample_id}" > ${sample_id}_analysis.txt
    wc -w ${input_file} >> ${sample_id}_analysis.txt
    """
}

workflow {
    // Create channel from files
    samples = channel.fromPath(params.input_pattern)
        .map { file ->
            def sample_id = file.baseName
            [sample_id, file]
        }

    // Run process
    analyzeFile(samples)
    analyzeFile.out.view()
}