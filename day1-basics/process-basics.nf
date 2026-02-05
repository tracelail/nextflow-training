#!/usr/bin/env nextflow

// process defines a task to execute -- like a function
process sayHello {
    // what the process is to produce
    output:
    // captures everything the process prints to the terminal (standard output stream) and turns it into a channel that can be passed to other processes.
    stdout

    // script is the actual command to run for the process
    script:
    """
    echo "Hello from Nextflow!"
    """
}

// workflow executes processes -- like a main function
workflow {
    sayHello()
    // .out accesses the output channel(s) of a process -- the output part of the process defines this.
    // .view() channel operator that prints the contents of a channel to the terminal -- used for inspection and debugging
    sayHello.out.view()
}