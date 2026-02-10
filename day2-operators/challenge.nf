#!/usr/bin/env nextflow

workflow {
    channel.of(
        ['patient1', 'tumor', 'file1.bam'],
        ['patient1', 'normal', 'file2.bam'],
        ['patient2', 'tumor', 'file3.bam'],
        ['patient1', 'tumor', 'file4.bam'],
        ['patient2', 'normal', 'file5.bam']
    )
    // YOUR CODE HERE
    .filter { id, type, file -> type == 'tumor' }
    .map { id, type, file -> [id, file] }
    .groupTuple()
    .view()
}
