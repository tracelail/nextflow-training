#!/usr/bin/env nextflow

/*
 * Session 12 — nf-test: Writing Tests for Your Pipeline
 *
 * A three-process pipeline that:
 *   1. Reads a CSV samplesheet into [meta, greeting] tuples
 *   2. Formats each greeting with SAY_HELLO
 *   3. Uppercases each result with CONVERT_UPPER
 *   4. Gathers all results and produces a summary with COLLECT_RESULTS
 *
 * 2026 syntax: lowercase channel factories, explicit closure parameters.
 */

include { SAY_HELLO      } from './modules/local/say_hello'
include { CONVERT_UPPER  } from './modules/local/convert_upper'
include { COLLECT_RESULTS } from './modules/local/collect_results'

params.input  = "${projectDir}/data/samplesheet/greetings.csv"
params.outdir = "results"

workflow {

    // ── 1. Parse the samplesheet into [meta, greeting] tuples ──────────────
    ch_input = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, language: row.language]
            [ meta, row.greeting ]
        }

    // ── 2. Format each greeting ─────────────────────────────────────────────
    SAY_HELLO(ch_input)

    // ── 3. Uppercase each formatted greeting ────────────────────────────────
    CONVERT_UPPER(SAY_HELLO.out.result)
    // CONVERT_UPPER.out.uppercased.view {greeting -> "Debug: ${greeting}"}
    // CONVERT_UPPER.out.uppercased.collect().view { collected -> "COLLECTED: ${collected}" }

    // ── 4. Gather all results and summarise ─────────────────────────────────
    COLLECT_RESULTS(CONVERT_UPPER.out.uppercased.map { item -> [item] }.collect()) // map is required here to maintain a tuple when collecting

    // ── 5. View summary ─────────────────────────────────────────────────────
    COLLECT_RESULTS.out.summary.view { summary -> "SUMMARY: ${summary}" }
}
