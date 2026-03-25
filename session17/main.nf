#!/usr/bin/env nextflow

// ============================================================
// Session 17 — Input validation with nf-schema
// ============================================================
// This pipeline demonstrates two-phase validation using the
// nf-schema plugin. Before any process runs, nf-schema checks:
//   Phase 1: All params match nextflow_schema.json rules
//   Phase 2: Samplesheet contents match assets/schema_input.json
// ============================================================

include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

include { WORD_COUNT } from './modules/local/word_count'
include { SUMMARIZE  } from './modules/local/summarize'

workflow {

    // --------------------------------------------------------
    // STEP 1 — Validate parameters (two-phase validation)
    // validateParameters() reads nextflow_schema.json and:
    //   - Checks every param type, format, pattern, and enum
    //   - Because params.input has "schema": "assets/schema_input.json"
    //     in nextflow_schema.json, samplesheet contents are also
    //     validated automatically here (Phase 2)
    // The pipeline halts with a clear error if anything is wrong.
    // --------------------------------------------------------
    validateParameters()

    // --------------------------------------------------------
    // STEP 2 — Log which params differ from their defaults
    // paramsSummaryLog() reads the schema to know defaults,
    // then returns a formatted string of overridden params only.
    // --------------------------------------------------------
    log.info paramsSummaryLog(workflow)

    // --------------------------------------------------------
    // STEP 3 — Build the input channel from the samplesheet
    //
    // samplesheetToList() does two things:
    //   1. Validates the file against assets/schema_input.json
    //      (a second, redundant validation — belt-and-suspenders)
    //   2. Returns a Groovy List, one entry per samplesheet row
    //
    // The schema controls what each entry looks like. Fields with
    // "meta": ["id"] are collected into a Map called meta.
    // Fields without "meta" become separate list elements.
    //
    // With our schema, each entry comes back as:
    //   [ [id: "sample1", condition: "tumor", replicate: "1"],
    //     /abs/path/to/sample1.txt ]
    //   ^--- meta map ---^           ^--- path element ---^
    //
    // Channel.fromList() converts the Groovy list into a queue channel.
    // --------------------------------------------------------
    ch_input = Channel.fromList(
        samplesheetToList(params.input, "${projectDir}/assets/schema_input.json")
    )

    // --------------------------------------------------------
    // STEP 4 — Optional: filter by condition
    // params.condition_filter is validated as enum by the schema
    // so we know it can only be "all", "tumor", or "normal" here.
    // --------------------------------------------------------
    ch_filtered = ch_input.filter { meta, data_file ->
        params.condition_filter == 'all' || meta.condition == params.condition_filter
    }

    // --------------------------------------------------------
    // STEP 5 — Run processes
    // --------------------------------------------------------
    WORD_COUNT(ch_filtered, params.min_word_length)

    SUMMARIZE(
        WORD_COUNT.out.counts.map { meta, counts -> counts }.collect(),
        params.suffix
    )
}
