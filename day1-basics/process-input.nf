#!/usr/bin/env nextflow

process greet {
    // what the process recieves
    input:
    // value input parameter
    val name

    output:
    stdout

    script:
    """
    echo "Hello, $name!"
    """
}

workflow {
    greet('Alice')
    greet.out.view()
}