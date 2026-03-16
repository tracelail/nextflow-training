#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    session15/main.nf
    Session 15: nf-core modules — Installing and using community components
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    This pipeline demonstrates:
      1. Installing nf-core modules (FASTQC, MULTIQC)
      2. The two input patterns: tuple val(meta), path(reads) vs plain path()
      3. Configuring modules via conf/modules.config (ext.args)
      4. Collecting per-sample outputs and aggregating with MULTIQC
      5. Gathering software versions from all modules
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// -------------------------------------------------------------------------------------
// STEP 1: Import the nf-core modules
//
// Note the path convention:
//   nf-core modules  → 'modules/nf-core/<tool>/main'     (directory/main.nf)
//   local modules    → 'modules/local/<name>'             (single .nf file)
//
// The process names are UPPERCASE — this is required by nf-core convention.
// -------------------------------------------------------------------------------------
include { FASTQC  } from './modules/nf-core/fastqc/main'
include { MULTIQC } from './modules/nf-core/multiqc/main'

// -------------------------------------------------------------------------------------
// STEP 2: Define the workflow
// -------------------------------------------------------------------------------------
workflow {

    // -- Read the samplesheet CSV and build the input channel ------------------
    //
    // splitCsv(header: true) turns each row into a map keyed by column name.
    // We then build the standard nf-core tuple: [ meta, [ reads ] ]
    //
    // The meta map carries sample identity through every process.
    // We set single_end based on whether fastq_2 is populated.
    //
    ch_reads = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id         : row.sample,
                single_end : row.fastq_2 ? false : true
            ]
            def reads = row.fastq_2
                ? [ file(row.fastq_1), file(row.fastq_2) ]
                : [ file(row.fastq_1) ]
            [ meta, reads ]
        }

    // Uncomment to inspect the channel structure before running:
    // ch_reads.view { meta, reads -> "Sample: ${meta.id}, files: ${reads}" }

    // -- STEP 3: Run FASTQC on every sample ------------------------------------
    //
    // FASTQC expects: tuple val(meta), path(reads)
    // It emits:
    //   FASTQC.out.html     → tuple val(meta), path("*.html")
    //   FASTQC.out.zip      → tuple val(meta), path("*.zip")
    //   FASTQC.out.versions → path("versions.yml")
    //
    FASTQC(ch_reads)

    // -- STEP 5: Collect QC files for MULTIQC ----------------------------------
    //
    // MULTIQC needs a flat list of all QC output files.
    // .map { meta, zips -> zips }  strips the meta map — MULTIQC doesn't use it.
    // .collect()                   gathers emissions from ALL samples into one list.
    //
    // We collect the .zip archives (not .html) because MultiQC reads the raw
    // data inside the zip to build its aggregated report.
    //
    ch_multiqc_files = FASTQC.out.zip
        .map { _meta, zips -> zips }
        .collect()

    // -- STEP 6: Run MULTIQC ---------------------------------------------------
    //
    // MULTIQC expects SIX inputs. Inputs 2-6 are all optional — pass [] to skip.
    //
    //   1. multiqc_files         ← required: all QC output files, collected
    //   2. multiqc_config        ← optional YAML config file
    //   3. extra_multiqc_config  ← optional second config
    //   4. multiqc_logo          ← optional custom logo PNG
    //   5. replace_names         ← optional sample rename TSV
    //   6. sample_names          ← optional sample names TSV
    //
    ch_multiqc_input = ch_multiqc_files.map {
        files ->
        [
            [id: 'multiqc'],          // the meta map
            files,         // collected QC files
            [],                       // multiqc_config
            [],                       // multiqc_logo
            [],                       // replace_names
            []                        // sample_names
        ]
    }

    MULTIQC(ch_multiqc_input)


    // -- STEP 7: Print completion summary --------------------------------------
    workflow.onComplete {
        log.info ""
        log.info "=========================================="
        log.info " Session 15 pipeline complete!"
        log.info "=========================================="
        log.info " Status   : ${workflow.success ? 'SUCCESS' : 'FAILED'}"
        log.info " Results  : ${params.outdir}/"
        log.info " Duration : ${workflow.duration}"
        log.info "=========================================="
        log.info ""
    }

}
