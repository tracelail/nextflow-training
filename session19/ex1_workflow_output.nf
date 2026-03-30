// ex1_workflow_output.nf
// Session 19 — Exercise 1 SOLUTION
//
// publishDir has been removed from every process.
// All publish decisions are centralised in the workflow output block.
//
// Run: nextflow run ex1_workflow_output.nf

params.input_dir = "${projectDir}/data"

// ─── Process 1: TRIM ─────────────────────────────────────────────────────────
// Notice: no publishDir here. The process is now purely computational.

process TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.txt"), emit: reads

    script:
    """
    echo "TRIMMED: \$(cat ${reads})" > ${meta.id}.trimmed.txt
    """
}

// ─── Process 2: COUNT ────────────────────────────────────────────────────────

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
    reads_ch = channel.fromPath("${params.input_dir}/*.txt")
        .map { file ->
            def meta = [id: file.baseName]
            [meta, file]
        }

    TRIM(reads_ch)
    COUNT(TRIM.out.reads)
    SUMMARISE(COUNT.out.counts.map { meta, f -> f }.collect())

    // ── PUBLISH SECTION ──────────────────────────────────────────────────────
    // This is the ONLY place publish decisions live.
    // Assignment syntax (=) — NOT >> (that was the old 24.04 preview syntax).

    publish:
    trimmed = TRIM.out.reads       // [meta, path] tuples → goes to 'trimmed' output
    counts  = COUNT.out.counts     // [meta, path] tuples → goes to 'counts' output
    summary = SUMMARISE.out.report // single path       → goes to 'summary' output
}

// ─── Output Block ─────────────────────────────────────────────────────────────
// Lives OUTSIDE the workflow block, at the top level of the file.
// Declares where each named output is published on disk.
// The output directory root defaults to 'results/' and can be changed
// with -output-dir on the command line or workflow.output.dir in config.

output {
    // Trimmed reads go into results/trimmed/
    trimmed {
        path 'trimmed'
    }

    // Count files go into results/counts/
    counts {
        path 'counts'
    }

    // Summary report goes directly into results/
    summary {
        path '.'
    }
}
