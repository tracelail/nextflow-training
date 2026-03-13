/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Local modules — written by you for this specific pipeline
include { SAY_HELLO } from '../modules/local/say_hello/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CORE PIPELINE WORKFLOW
    ─────────────────────────────────────────────────────────────────────────────────
    This is the named workflow that contains the actual pipeline logic.
    It is called from NFCORE_GREETINGS in main.nf.
    ─────────────────────────────────────────────────────────────────────────────────
    NOTES FOR LEARNERS:
      take:  declares input channels — no channel factories here.
             The caller (NFCORE_GREETINGS) passes channels in.
      main:  all process calls and channel operations go here.
      emit:  exposes named outputs so the caller can access them.
             Always declare these even if they are empty channels.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GREETINGS {

    take:
    ch_samplesheet // channel: [ val(meta), val(greeting) ]

    main:

    // ch_versions collects software version info from each process.
    // Each process outputs a versions.yml file; we mix them all together here
    // so they can be passed to a version-reporting step (e.g., MultiQC).
    ch_versions = channel.empty()

    //
    // MODULE: SAY_HELLO
    // Writes each greeting to a text file named after the sample.
    //
    SAY_HELLO (
        ch_samplesheet
    )

    // Mix this process's versions output into the running ch_versions channel.
    // .first() is used because versions.yml is the same for every task instance
    // of the same process — we only need one copy.
    ch_versions = ch_versions.mix(SAY_HELLO.out.versions.first())

    emit:
    txt            = SAY_HELLO.out.txt   // channel: [ val(meta), path("*.txt") ]
    versions       = ch_versions          // channel: path("versions.yml")
    multiqc_report = channel.empty()      // channel: path("*multiqc_report.html")
                                          // (empty for now — populated in Session 15
                                          //  when MultiQC is added)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NOTES FOR LEARNERS
    ─────────────────────────────────────────────────────────────────────────────────
    Why is multiqc_report emitted as an empty channel?

    The NFCORE_GREETINGS wrapper in main.nf expects this workflow to emit
    multiqc_report (look at its emit: block). If we don't emit it, the pipeline
    will crash with "No such output: multiqc_report". Emitting an empty channel
    is the correct way to satisfy the interface contract while the feature isn't
    implemented yet.

    Why does SAY_HELLO receive ch_samplesheet directly?

    ch_samplesheet already contains [meta, greeting] tuples, which is exactly
    what SAY_HELLO's input: block expects:
        input: tuple val(meta), val(greeting)
    There is no transformation needed before passing it in.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
