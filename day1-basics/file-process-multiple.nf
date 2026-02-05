#!/usr/bin/env nextflow

process countLines {
    input:
    // input path parameter is for files
    path input_file

    output:
    stdout
    // Capture any `.txt` files that this process -countLines- creates in its working directory
    path "*.txt", emit: line_counts //named output - Tag this output channel with the name `line_counts`

    script:
    """
    wc -l $input_file > ${input_file.baseName}-wc.txt
    """
}

workflow {
    //channel.fromPath creates a channel from files
    file_ch = channel.fromPath('sample*.txt')
    countLines(file_ch)
    countLines.out.line_counts.view()
}