#!/usr/bin/env nextflow

/*
 * COMPARISON FILE — Session 3 original vs Session 14 nf-core structure
 *
 * This file is FOR READING ONLY. It shows the Session 3 pipeline code
 * side-by-side with commentary explaining what changed in Session 14.
 * Run the files in exercise3_nfcore_conversion/ instead.
 */

// ══════════════════════════════════════════════════════════════════════════════
// SESSION 3 ORIGINAL (all in one file, no template)
// ══════════════════════════════════════════════════════════════════════════════

/*
// Session 3 main.nf — everything in one file

nextflow.enable.dsl = 2

params.outdir = 'results'

process SAY_HELLO {
    publishDir params.outdir, mode: 'copy'

    input: val(greeting)
    output: path("*.txt")

    script:
    """
    echo "${greeting}" > ${greeting}.txt
    """
}

process CONVERT_UPPER {
    input: val(text)
    output: val(upper_text)

    exec:
    upper_text = text.toUpperCase()
}

process COLLECT_RESULTS {
    publishDir params.outdir, mode: 'copy'

    input: path(files)
    output: path("all_greetings.txt")

    script:
    """
    cat ${files} > all_greetings.txt
    """
}

workflow {
    ch_greetings = channel.of('Hello', 'Bonjour', 'Holà')
    SAY_HELLO(ch_greetings)
    CONVERT_UPPER(SAY_HELLO.out)
    COLLECT_RESULTS(CONVERT_UPPER.out.collect())
}
*/

// ══════════════════════════════════════════════════════════════════════════════
// WHAT CHANGED IN SESSION 14 — and WHY
// ══════════════════════════════════════════════════════════════════════════════

/*
CHANGE 1: Input source
──────────────────────
Session 3:   channel.of('Hello', 'Bonjour', 'Holà')
             Greetings are hardcoded in the workflow block.

Session 14:  params.input = 'assets/samplesheet.csv'
             PIPELINE_INITIALISATION reads the CSV and emits [meta, greeting] tuples.

Why? Pipelines need to be runnable with different inputs without editing code.
     A samplesheet also allows richer metadata (sample IDs, conditions, etc.)
     that travels with the data throughout the pipeline.


CHANGE 2: Process structure
────────────────────────────
Session 3:   Minimal — input, output, script/exec only.

Session 14:  Adds: tag, label, when guard, ext.args pattern,
                   versions.yml output, stub block.

Why? These additions make the process:
     - Identifiable in logs (tag)
     - Resource-aware on HPC (label)
     - Conditionally skippable (when)
     - Configurable without code changes (ext.args)
     - Version-reportable (versions.yml)
     - Testable without running the tool (stub)


CHANGE 3: Output type (CONVERT_UPPER)
──────────────────────────────────────
Session 3:   output: val(upper_text)   — a string in memory
Session 14:  output: path("*.upper.txt") — a file on disk

Why? Files are resumable. A val output cannot be cached and recovered
     on -resume. In a real pipeline, this step would transform a BAM file,
     not a string — so output: path is the correct model.
     (Session 3 used val as a teaching simplification.)


CHANGE 4: Process location
────────────────────────────
Session 3:   All processes defined in main.nf
Session 14:  Each process in its own file: modules/local/<n>/main.nf

Why? Separation of concerns. In an nf-core pipeline with 20+ modules,
     having everything in main.nf becomes unmanageable. Separate files
     allow processes to be installed, updated, and shared independently.


CHANGE 5: publishDir location
───────────────────────────────
Session 3:   publishDir inside the process definition
Session 14:  publishDir in conf/modules.config, NOT in the process

Why? If publishDir is in the process, changing the output path requires
     editing module code. In nf-core, users configure output paths via
     config files — module code never needs to change.


CHANGE 6: Workflow location
─────────────────────────────
Session 3:   workflow { ... } in main.nf
Session 14:  core logic in workflows/greetings.nf
             entry point in main.nf delegates to it

Why? The take:/main:/emit: pattern makes the pipeline importable.
     Another pipeline can do:
         include { NFCORE_GREETINGS } from './path/to/nf-core-greetings/main'
     and use this entire pipeline as a subworkflow.
*/
