// ex2_lineage.nf
// Session 19 — Exercise 2
//
// Same three-process pipeline as Exercise 1, but configured for data lineage.
// The nextflow.config alongside this file enables lineage tracking.
//
// Steps:
//   1. nextflow run ex2_lineage.nf
//   2. nextflow lineage list
//   3. nextflow lineage view lid://<paste LID>
//   4. nextflow lineage view lid://<LID>/results/counts/<file>
//   5. nextflow lineage render lid://<LID>/results/summary/pipeline_report.txt
//
// NOTE: Data lineage ONLY tracks files published via the workflow output block.
// Files from publishDir in processes do NOT get lineage records.

params.input_dir = "${projectDir}/data"

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
