#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    exercises/01_basic/main.nf
    BASIC EXERCISE: Install and wire the FASTQC module
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Goal: Get FASTQC running on all 4 samples from the samplesheet.

    Before running this file you need to install the module. Run this from
    the session15/ directory:

        cd /home/trace/projects/nextflow-training/session15
        nf-core modules install fastqc

    That command will:
      - Download modules/nf-core/fastqc/main.nf
      - Download modules/nf-core/fastqc/environment.yml
      - Download modules/nf-core/fastqc/meta.yml
      - Download modules/nf-core/fastqc/tests/
      - Create/update modules.json

    Then run this exercise:
        nextflow run exercises/01_basic/main.nf -profile docker --outdir results_basic

    EXPECTED OUTCOME:
      - FASTQC runs 4 times (once per sample) in parallel
      - results_basic/fastqc/ contains 4 HTML reports
      - Each HTML file is named <sample_id>_fastqc.html or similar

    YOUR TASK:
      The pipeline below is incomplete. Fill in the ??? sections to make it work.
      Hints are provided in the comments.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TASK 1: Add the include statement for FASTQC
// The module lives at: modules/nf-core/fastqc/main.nf
// The process name is: FASTQC
// Hint: include { PROCESS_NAME } from 'path/to/module/main'
// (paths are relative to THIS file's location in exercises/01_basic/)
include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

workflow {

    // TASK 2: Build the input channel from the samplesheet
    // The samplesheet is at: ../../assets/samplesheet.csv
    // Columns: sample, fastq_1, fastq_2, strandedness
    // You need to produce: channel of [ meta, reads ] tuples
    // where meta = [ id: row.sample, single_end: false ] (all samples are paired)
    // and reads = [ file(row.fastq_1), file(row.fastq_2) ]
    //
    ch_reads = channel
        .fromPath('assets/samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta  = [ id: row.sample, single_end: false ]
            def reads = [ file(row.fastq_1), file(row.fastq_2)]
            [ meta, reads ]
        }

    // TASK 3: Call FASTQC with the reads channel
    // Hint: it's just like calling a local process
    FASTQC(ch_reads)

    // TASK 4: Print the HTML output paths so you can see what was produced
    // Hint: FASTQC.out.html is a channel of [ meta, path ] tuples
    // Use .view to print: "Sample: <id> → <html_file>"
    // Hint: use an explicit closure parameter, not 'it'
    FASTQC.out.html.view {meta, html -> "Sample: ${meta.id}, ${html}"}

}
