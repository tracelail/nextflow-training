#!/usr/bin/env nextflow

process countLines {
    input:
    // input path parameter is for files
    path input_file

    output:
    stdout

    script:
    """
    wc -l $input_file
    """
}

workflow {
    //channel.fromPath creates a channel from files
    file_ch = channel.fromPath('sample.txt')
    countLines(file_ch)
    countLines.out.view()
}