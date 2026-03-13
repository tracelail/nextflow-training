/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
    ─────────────────────────────────────────────────────────────────────────────────
    All three processes from Session 3 are now local modules.
    Each lives in its own directory: modules/local/<name>/main.nf
    This is the nf-core convention for local (pipeline-specific) modules.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAY_HELLO      } from '../modules/local/say_hello/main'
include { CONVERT_UPPER  } from '../modules/local/convert_upper/main'
include { COLLECT_RESULTS } from '../modules/local/collect_results/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CORE PIPELINE WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GREETINGS {

    take:
    ch_samplesheet // channel: [ val(meta), val(greeting) ]

    main:

    ch_versions = channel.empty()

    //
    // MODULE: SAY_HELLO
    // Input:  [ val(meta), val(greeting) ]
    // Output: txt: [ val(meta), path("*.txt") ]
    //
    SAY_HELLO (
        ch_samplesheet
    )
    ch_versions = ch_versions.mix(SAY_HELLO.out.versions.first())

    //
    // MODULE: CONVERT_UPPER
    // Input:  [ val(meta), path("*.txt") ]   ← output of SAY_HELLO
    // Output: upper: [ val(meta), path("*.txt") ]
    //
    CONVERT_UPPER (
        SAY_HELLO.out.txt
    )
    ch_versions = ch_versions.mix(CONVERT_UPPER.out.versions.first())

    //
    // MODULE: COLLECT_RESULTS
    // Input:  path("*.txt")  ← all upper files collected into a single task
    // Output: collected: path("all_greetings.txt")
    //
    // .map transforms [ val(meta), path(file) ] → path(file) to strip the meta.
    // .collect() gathers all items from the channel into a single list,
    //            converting the queue channel to a value channel.
    // The COLLECT_RESULTS process then runs once with all files as its input.
    //
    ch_upper_files = CONVERT_UPPER.out.upper.map { meta, file -> file }.collect()

    COLLECT_RESULTS (
        ch_upper_files
    )
    ch_versions = ch_versions.mix(COLLECT_RESULTS.out.versions)

    emit:
    greetings      = SAY_HELLO.out.txt         // channel: [ val(meta), path("*.txt") ]
    upper          = CONVERT_UPPER.out.upper   // channel: [ val(meta), path("*.txt") ]
    collected      = COLLECT_RESULTS.out.all   // channel: path("all_greetings.txt")
    versions       = ch_versions               // channel: path("versions.yml")
    multiqc_report = channel.empty()           // channel: path("*multiqc_report.html")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NOTES FOR LEARNERS
    ─────────────────────────────────────────────────────────────────────────────────
    Session 3 vs Session 14 — what changed in the workflow block?

    Session 3 pattern (monolithic main.nf):
        ch_greetings = channel.fromList(['Hello', 'Bonjour', 'Holà'])
        SAY_HELLO(ch_greetings)

    Session 14 pattern (nf-core template):
        The channel already exists as ch_samplesheet when we get here.
        PIPELINE_INITIALISATION in main.nf parsed the CSV samplesheet
        and emitted [ meta, greeting ] tuples. We just use them.

    The process calls themselves are identical — only where the input
    channel comes from has changed (samplesheet → channel, not inline list).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
