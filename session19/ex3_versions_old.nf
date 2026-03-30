// ex3_versions_old.nf
// Session 19 — Exercise 3 starting point (OLD pattern)
//
// This pipeline uses the OLD nf-core versions.yml approach:
//   - Every process writes a versions.yml file
//   - The workflow manually mixes them all together
//   - This is the boilerplate you will eliminate in ex3_versions_topic.nf
//
// Run it first so you understand what it does:
//   nextflow run ex3_versions_old.nf
//   cat results/software_versions.yml

params.input_dir = "${projectDir}/data"

// ─── Process 1: TRIM ─────────────────────────────────────────────────────────
// OLD pattern: writes versions.yml in every script block

process TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.txt"), emit: reads
    path "versions.yml",                             emit: versions   // <-- OLD

    script:
    // The version heredoc at the end of every script is the boilerplate to eliminate
    """
    echo "TRIMMED: \$(cat ${reads})" > ${meta.id}.trimmed.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(echo --version 2>&1 | head -1)
    END_VERSIONS
    """
}

// ─── Process 2: COUNT ────────────────────────────────────────────────────────

process COUNT {
    tag "${meta.id}"

    input:
    tuple val(meta), path(trimmed)

    output:
    tuple val(meta), path("${meta.id}.counts.txt"), emit: counts
    path "versions.yml",                            emit: versions   // <-- OLD

    script:
    """
    wc -w ${trimmed} | awk '{print \$1}' > ${meta.id}.counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk --version 2>&1 | head -1)
    END_VERSIONS
    """
}

// ─── Process 3: SUMMARISE ────────────────────────────────────────────────────

process SUMMARISE {
    input:
    path count_files

    output:
    path "pipeline_report.txt", emit: report
    path "versions.yml",        emit: versions   // <-- OLD

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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$( bash --version | head -1 )
    END_VERSIONS
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

    // ── OLD version mixing — must do this for EVERY module call ──────────────
    // If you add a 4th module you must add another .mix() line.
    // This is the wiring overhead topic channels eliminate.
    ch_versions = channel.empty()
    ch_versions = ch_versions.mix(TRIM.out.versions.first())     // <-- OLD
    ch_versions = ch_versions.mix(COUNT.out.versions.first())    // <-- OLD
    ch_versions = ch_versions.mix(SUMMARISE.out.versions)        // <-- OLD

    ch_versions
        .collectFile(name: 'software_versions.yml', storeDir: 'results', newLine: true)

    publish:
    trimmed = TRIM.out.reads
    counts  = COUNT.out.counts
    summary = SUMMARISE.out.report
}

output {
    trimmed { path 'trimmed' }
    counts  { path 'counts'  }
    summary { path '.'       }
}
