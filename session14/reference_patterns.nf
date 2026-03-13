#!/usr/bin/env nextflow

/*
 * Session 14 — Annotated Reference: nf-core Structural Patterns
 *
 * This file is NOT meant to be run. It is a reference card showing
 * every structural pattern introduced in Session 14, with annotations
 * explaining what each part does and why it exists.
 */

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 1: Three-layer delegation in main.nf
// ─────────────────────────────────────────────────────────────────────────────

// Layer 3: core logic — defined in workflows/mypipeline.nf
// (not shown here — lives in its own file)

// Layer 2: named wrapper — importable by other pipelines
workflow NFCORE_MYPIPELINE {

    take:
    samplesheet             // channel passed in from the unnamed workflow

    main:
    MYPIPELINE ( samplesheet )

    emit:
    multiqc_report = MYPIPELINE.out.multiqc_report
}

// Layer 1: unnamed entry — Nextflow runs this when you execute nextflow run
workflow {

    main:
    PIPELINE_INITIALISATION ( /* params... */ )  // parse & validate input
    NFCORE_MYPIPELINE ( PIPELINE_INITIALISATION.out.samplesheet )
    PIPELINE_COMPLETION ( /* params + output channels... */ )  // reports & email
}

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 2: Composable workflow with take/main/emit (in workflows/mypipeline.nf)
// ─────────────────────────────────────────────────────────────────────────────

workflow MYPIPELINE {

    take:
    // Declare what channels this workflow needs.
    // Types are comments — they document the channel structure.
    ch_samplesheet  // channel: [ val(meta), path(reads) ]

    main:
    ch_versions = channel.empty()     // accumulator for software versions

    PROCESS_ONE ( ch_samplesheet )
    ch_versions = ch_versions.mix(PROCESS_ONE.out.versions.first())

    PROCESS_TWO ( PROCESS_ONE.out.results )
    ch_versions = ch_versions.mix(PROCESS_TWO.out.versions.first())

    emit:
    // Always declare outputs even if they are empty channels.
    // The caller (NFCORE_MYPIPELINE) expects these names.
    results        = PROCESS_TWO.out.results   // real output
    multiqc_report = channel.empty()           // not yet implemented
    versions       = ch_versions               // version info for reporting
}

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 3: nf-core-compliant process (in modules/local/<n>/main.nf)
// ─────────────────────────────────────────────────────────────────────────────

process MY_TOOL {

    tag "$meta.id"          // shown in Nextflow log beside each task
    label 'process_medium'  // maps to CPUs/memory in conf/base.config

    // Container and Conda directives go here in a real module:
    // conda "${moduleDir}/environment.yml"
    // container "docker.io/biocontainers/mytool:1.0.0"

    input:
    tuple val(meta), path(reads)    // always tuple val(meta), path(...)

    output:
    tuple val(meta), path("*.bam"), emit: bam      // named output
    path "versions.yml",            emit: versions  // always present

    when:
    task.ext.when == null || task.ext.when   // allows ext.when = false in config

    script:
    def args   = task.ext.args   ?: ''          // from modules.config
    prefix     = task.ext.prefix ?: "${meta.id}" // NO def — visible to output block
    """
    mytool \\
        $args \\
        -o ${prefix}.bam \\
        $reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mytool: \$(mytool --version 2>&1 | head -1)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mytool: \$(mytool --version 2>&1 | head -1)
    END_VERSIONS
    """
}

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 4: modules.config — the central control panel (in conf/modules.config)
// ─────────────────────────────────────────────────────────────────────────────

/*
process {
    // Default publishDir for every process
    publishDir = [
        path: { "${params.outdir}/${task.process.tokenize(':')[-1].tokenize('_')[0].toLowerCase()}" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]

    withName: 'MY_TOOL' {
        // STATIC ext.args — no closure needed for literal strings
        ext.args = '--flag --option value'

        // DYNAMIC ext.args — MUST use a closure when referencing params.*
        ext.args = { params.stringency ? "--stringency ${params.stringency}" : '' }

        // Override the output file name prefix
        ext.prefix = { "${meta.id}_aligned" }

        // Disable this process entirely via config
        // ext.when = false

        publishDir = [
            path: { "${params.outdir}/aligned" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
    }
}
*/

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 5: publishDir path expression explained
// ─────────────────────────────────────────────────────────────────────────────

/*
Given: task.process = "NFCORE_GREETINGS:GREETINGS:SAY_HELLO"

Step by step:
  task.process.tokenize(':')       → ['NFCORE_GREETINGS', 'GREETINGS', 'SAY_HELLO']
  [-1]                             → 'SAY_HELLO'
  .tokenize('_')                   → ['SAY', 'HELLO']
  [0]                              → 'SAY'
  .toLowerCase()                   → 'say'

Final path: ${params.outdir}/say/

Override in the withName block to use a more descriptive path like 'greetings/'.
*/

// ─────────────────────────────────────────────────────────────────────────────
// PATTERN 6: Scatter-gather inside a workflow (as used in COLLECT_RESULTS)
// ─────────────────────────────────────────────────────────────────────────────

/*
ch_samplesheet
    │ scatter: SAY_HELLO runs once per element (3 tasks)
    ▼
SAY_HELLO.out.txt          channel: [ meta1, file1 ], [ meta2, file2 ], [ meta3, file3 ]
    │ strip meta and collect all files into one list
    ▼
.map { meta, file -> file }  channel: file1, file2, file3
.collect()                   channel: [ file1, file2, file3 ]  (value channel — one item)
    │ gather: COLLECT_RESULTS runs ONCE with all 3 files
    ▼
COLLECT_RESULTS.out.all    channel: all_greetings.txt
*/
