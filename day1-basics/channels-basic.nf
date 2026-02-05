#!/usr/bin/env nextflow

process greet {
    input:
    val name

    output:
    stdout

    script:
    """
    echo "Hello, $name!"
    """
}

workflow {
    // Create a channel with multiple values
    names_ch = channel.of('Alice', 'Bob', 'Charlie')

    // Process each name
    greet(names_ch)
    greet.out.view()
}

// channels can parallize a process, processing multiple items at once.
// !!! Like a for loop but parallel without the need to code an threading or multiprocessing