#!/usr/bin/env nextflow

workflow {
    // Keep only even numbers
    channel.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        .filter { num -> num % 2 == 0 }
        .view()
}
