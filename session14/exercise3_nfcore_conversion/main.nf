#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/greetings  — Exercise 3: Session 3 pipeline in nf-core template format
    ─────────────────────────────────────────────────────────────────────────────────
    This is the Session 3 three-process pipeline (SAY_HELLO → CONVERT_UPPER →
    COLLECT_RESULTS) restructured to match the nf-core template layout exactly.

    Compare this to the original session03/main.nf to see the transformation.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { GREETINGS               } from './workflows/greetings'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_greetings_pipeline/main'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_greetings_pipeline/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WRAPPER — this is the importable "public API" of the pipeline.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NFCORE_GREETINGS {

    take:
    samplesheet

    main:
    GREETINGS (
        samplesheet
    )

    emit:
    collected      = GREETINGS.out.collected
    multiqc_report = GREETINGS.out.multiqc_report
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    UNNAMED ENTRY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    NFCORE_GREETINGS (
        PIPELINE_INITIALISATION.out.samplesheet
    )

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
