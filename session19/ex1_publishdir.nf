// ex1_publishdir.nf
// Session 19 — Exercise 1 starting point
//
// This pipeline has THREE processes each with their own publishDir.
// Publish logic is scattered and inconsistent.
// Your job: replace all of it with a single workflow output block.
//
// Run: nextflow run ex1_publishdir.nf

params.input_dir = "${projectDir}/data"
params.outdir    = "results"

// ─── Process 1: TRIM ─────────────────────────────────────────────────────────
// Simulates trimming reads. Writes a trimmed file per sample.
// NOTE: publishDir is here, in the process — we want to move this out.

process TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.txt"), emit: reads

    script:
    """
    # Simulate trimming: just copy and annotate
    echo "TRIMMED: \$(cat ${reads})" > ${meta.id}.trimmed.txt
    """
}

// ─── Process 2: COUNT ────────────────────────────────────────────────────────
// Simulates counting words. Writes a counts file per sample.

process COUNT {
    tag "${meta.id}"

    input:
    tuple val(meta), path(trimmed)

    output:
    tuple val(meta), path("${meta.id}.counts.txt"), emit: counts

    script:
    """
    wc -w ${trimmed} | awk '{print \$1}' > ${meta.id}.counts.txt
    """
}

// ─── Process 3: SUMMARISE ────────────────────────────────────────────────────
// Aggregates all counts into a single report.

process SUMMARISE {

    input:
    path count_files

    output:
    path "pipeline_report.txt", emit: report

    script:
    """
    echo "=== Pipeline Summary ===" > pipeline_report.txt
    echo "Samples processed: \$(ls *.counts.txt | wc -l)" >> pipeline_report.txt
    echo "" >> pipeline_report.txt
    for f in *.counts.txt; do
        sample=\${f%.counts.txt}
        count=\$(cat \$f)
        echo "  \${sample}: \${count} words" >> pipeline_report.txt
    done
    """
}

// ─── Workflow ─────────────────────────────────────────────────────────────────

workflow {
    main:

    // Build input channel from the data/ directory
    reads_ch = channel.fromPath("${params.input_dir}/*.txt")
        .map { file ->
            def meta = [id: file.baseName]
            [meta, file]
        }

    // Run the three steps
    TRIM(reads_ch)
    COUNT(TRIM.out.reads)
    SUMMARISE(COUNT.out.counts.map { meta, f -> f }.collect())

    // You will add publish: and output {} blocks here in ex1_workflow_output.nf
    publish:
    trimmed = TRIM.out.reads
    counts  = COUNT.out.counts
    summary = SUMMARISE.out.report
}

output {
    trimmed {
        path 'trimmed'
    }
    counts {
        path 'counts'
    }
    summary {
        path '.'
    }
}
