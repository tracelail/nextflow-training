#!/usr/bin/env nextflow

workflow {
    // Reverse each string
    channel.of('hello', 'world', 'nextflow')
        .map { word -> word.reverse() } // map applies a function to every item
        .view()
}

// makes 'hello' -> 'olleh' and so on