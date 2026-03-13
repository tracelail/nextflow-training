#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/greetings
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/greetings
    Website: https://nf-co.re/greetings
    Slack  : https://nfcore.slack.com/channels/greetings
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT WORKFLOWS AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GREETINGS              } from './workflows/greetings'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_greetings_pipeline/main'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_greetings_pipeline/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW — acts as the "public API" of this pipeline.
    Other pipelines can import and call NFCORE_GREETINGS directly.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NFCORE_GREETINGS {

    take:
    samplesheet // channel: path(samplesheet.csv)

    main:
    GREETINGS (
        samplesheet
    )

    emit:
    multiqc_report = GREETINGS.out.multiqc_report
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    UNNAMED ENTRY WORKFLOW — Nextflow runs this block when you execute main.nf.
    It handles pipeline initialisation, calls the named wrapper, then handles
    pipeline completion (email, reports).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // SUBWORKFLOW: Validate parameters, parse samplesheet, check Nextflow version
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    //
    // WORKFLOW: Call the named wrapper which calls the core pipeline workflow
    //
    NFCORE_GREETINGS (
        PIPELINE_INITIALISATION.out.samplesheet
    )

    //
    // SUBWORKFLOW: Send completion email, generate pipeline report
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        NFCORE_GREETINGS.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NOTES FOR LEARNERS
    ─────────────────────────────────────────────────────────────────────────────────
    KEY POINT 1: Three-layer delegation
      workflow {} (unnamed)
          └── NFCORE_GREETINGS (named wrapper, same file)
                  └── GREETINGS (core logic, in workflows/greetings.nf)

    KEY POINT 2: Process names
      Because GREETINGS is called inside NFCORE_GREETINGS, and NFCORE_GREETINGS
      is called from the unnamed workflow, Nextflow generates fully qualified
      process names like:
          NFCORE_GREETINGS:GREETINGS:SAY_HELLO
      This full name is what 'withName' selectors in modules.config can target.

    KEY POINT 3: The samplesheet flow
      PIPELINE_INITIALISATION reads params.input (the CSV file path), validates it
      against assets/schema_input.json using the nf-schema plugin, and emits a
      structured channel of [meta, greeting] tuples.
      That channel passes through NFCORE_GREETINGS.take → GREETINGS.take.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
