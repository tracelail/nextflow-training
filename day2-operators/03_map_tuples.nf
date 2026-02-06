#!/usr/bin/env nextflow

// workflow {
//     // Create [filename, filepath] tuples
//     channel.fromPath('data/*.txt')
//         .map { file -> [file.baseName, file] }
//         .view { tuple -> "Name: ${tuple[0]}, Path: ${tuple[1]}" }
// }

// more explicit way to unpack anonymous tuples
workflow {
    // Create [filename, filepath] tuples
    channel.fromPath('data/*.txt')
        .map { file -> [file.baseName, file] }
        .view { filename, filepath -> "Name: ${filename}, Path: ${filepath}" }
}
