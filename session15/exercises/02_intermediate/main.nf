#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    exercises/02_intermediate/main.nf
    INTERMEDIATE EXERCISE: Chain FASTQC → MULTIQC and configure via ext.args
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Goal: Add MULTIQC downstream of FASTQC and configure both modules
    via a conf/modules.config file.

    Before running, install both modules from session15/:
        nf-core modules install fastqc
        nf-core modules install multiqc

    Run with:
        nextflow run exercises/02_intermediate/main.nf \
            -profile docker \
            -c exercises/02_intermediate/modules.config \
            --outdir results_intermediate

    EXPECTED OUTCOME:
      - FASTQC runs 4 times in parallel
      - MULTIQC runs once after FASTQC finishes
      - results_intermediate/multiqc/multiqc_report.html exists
      - The report shows all 4 samples

    YOUR TASKS (marked with ???):
      1. Add include for MULTIQC
      2. Build the ch_multiqc_files channel from FASTQC zip output
      3. Call MULTIQC with the correct 6 arguments
      4. Create exercises/02_intermediate/modules.config with ext.args for both tools

    HINT for MULTIQC inputs:
      - Arg 1: collected QC files (strip meta, then collect)
      - Args 2-6: [] for optional inputs you don't need
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC  } from '../../modules/nf-core/fastqc/main'
// TASK 1: Add the MULTIQC include statement
include { MULTIQC } from '../../modules/nf-core/multiqc/main'

workflow {

    ch_reads = channel
        .fromPath('assets/samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta  = [ id: row.sample, single_end: false ]
            def reads = [ file(row.fastq_1), file(row.fastq_2) ]
            [ meta, reads ]
        }

    FASTQC(ch_reads)

    // TASK 2: Build the MultiQC input channel
    // - Take FASTQC.out.zip
    // - Strip the meta map (MULTIQC doesn't need it)
    //   Hint: .map { meta, zips -> zips }
    // - Collect into a single list
    //   Hint: .collect()
    //
    ch_multiqc_files = FASTQC.out.zip
        .map { _meta, files -> files }
        .collect() // your channel transformation here

    ch_multiqc_input = ch_multiqc_files
        .map {
            files ->
            [
                [id: 'multiqc'],
                files,
                [],
                [],
                [],
                []

            ]
        }

    // TASK 3: Call MULTIQC
    // Remember: 6 arguments. Only the first is required.
    MULTIQC(ch_multiqc_input)

    // Verify the report was produced
    MULTIQC.out.report.view { report -> "MultiQC report: ${report}" }

}
