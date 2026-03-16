#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    exercises/03_challenge/main.nf
    CHALLENGE EXERCISE: Module patching + conditional execution with ext.when
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    This exercise has two independent parts. Do them in order.

    ─────────────────────────────────────────────────────────────────────────────────
    PART A — Conditional execution with ext.when
    ─────────────────────────────────────────────────────────────────────────────────
    Goal: Add a --skip_fastqc parameter so FastQC can be skipped entirely without
    removing it from the workflow code.

    nf-core modules support this via ext.when in conf/modules.config:
        withName: 'FASTQC' {
            ext.when = { !params.skip_fastqc }
        }

    When ext.when evaluates to false, the process is silently skipped.
    The output channels still exist but emit nothing — downstream processes
    gracefully receive empty channels.

    YOUR TASK:
    1. Add params.skip_fastqc = false to your nextflow.config
    2. Add ext.when for FASTQC in conf/modules.config
    3. Test: nextflow run exercises/03_challenge/main.nf -profile docker
    4. Test: nextflow run exercises/03_challenge/main.nf -profile docker --skip_fastqc

    In run 4, FASTQC should not appear in the task list at all.
    MULTIQC will run but produce a near-empty report — that's expected.

    ─────────────────────────────────────────────────────────────────────────────────
    PART B — Understanding module patching
    ─────────────────────────────────────────────────────────────────────────────────
    Goal: Make a small local modification to the installed FASTQC module
    and track it with nf-core modules patch.

    Scenario: You want FASTQC to add an extra log line showing the sample ID.
    You edit modules/nf-core/fastqc/main.nf to add this to the script block:
        echo "Running FastQC on sample: ${meta.id}"

    If you then run:  nf-core modules lint fastqc
    It will FAIL because your local copy no longer matches the remote.

    The fix:  nf-core modules patch fastqc
    This generates:  modules/nf-core/fastqc/fastqc.diff
    And updates modules.json to record the patch.
    Now:  nf-core modules lint fastqc  → passes

    Later, when you run:  nf-core modules update fastqc
    Your patch is re-applied on top of the updated module automatically.

    STEPS TO PRACTICE (run these commands in the session15/ directory):
    1.  cat modules/nf-core/fastqc/main.nf   (read the current file)
    2.  Edit the script: block to add a debug echo line after def prefix = ...
    3.  nf-core modules lint fastqc          (observe the failure)
    4.  nf-core modules patch fastqc         (generate the patch)
    5.  cat modules/nf-core/fastqc/fastqc.diff   (inspect the patch)
    6.  nf-core modules lint fastqc          (observe it now passes)
    7.  cat modules.json                     (see that the patch is recorded)

    REFLECTION QUESTIONS (no code needed):
    a. What happens to your patch if the same lines change in an upstream update?
    b. Why is nf-core's patch system preferable to forking the whole modules repo?
    c. When would you use ext.args instead of patching?
       (Answer: almost always — patch only when ext.args cannot express the change)

    ─────────────────────────────────────────────────────────────────────────────────
    The pipeline code for Part A is below.
    ─────────────────────────────────────────────────────────────────────────────────
*/

include { FASTQC  } from '../../modules/nf-core/fastqc/main'
include { MULTIQC } from '../../modules/nf-core/multiqc/main'

workflow {

    ch_reads = channel
        .fromPath('../../assets/samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta  = [ id: row.sample, single_end: false ]
            def reads = [ file(row.fastq_1), file(row.fastq_2) ]
            [ meta, reads ]
        }

    // FASTQC is skipped when params.skip_fastqc is true (via ext.when in config)
    FASTQC(ch_reads)

    // When FASTQC is skipped, FASTQC.out.zip emits nothing.
    // .ifEmpty([]) ensures MULTIQC still receives something (an empty list).
    ch_multiqc_files = FASTQC.out.zip
        .map { meta, zips -> zips }
        .collect()
        .ifEmpty([])

    MULTIQC(
        ch_multiqc_files,
        [],
        [],
        [],
        [],
        []
    )

    workflow.onComplete {
        def skip_msg = params.skip_fastqc ? " (FastQC was skipped)" : ""
        log.info "Pipeline complete${skip_msg}. Results in: ${params.outdir}"
    }

}
