// ex3_versions_topic.nf
// Session 19 — Exercise 3 SOLUTION (topic channels + eval)
//
// What changed from ex3_versions_old.nf:
//   REMOVED from each process:
//     - path "versions.yml", emit: versions
//     - the versions.yml heredoc in every script block
//   ADDED to each process output block:
//     - tuple val(...), val(...), eval('...'), emit: versions_<tool>, topic: versions
//   REMOVED from the workflow:
//     - ch_versions = channel.empty()
//     - all the ch_versions.mix(...) lines
//   ADDED to the workflow:
//     - channel.topic('versions') subscription to collect everything
//
// Run: nextflow run ex3_versions_topic.nf
// Then: cat results/software_versions.txt

params.input_dir = "${projectDir}/data"

// ─── Process 1: TRIM ─────────────────────────────────────────────────────────

process TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.txt"),  emit: reads

    // NEW: emit version info via topic channel, no file needed
    // - val("${task.process}") : emits the full process name, e.g. "TRIM"
    // - val('bash')            : the tool name (a plain string), should be Fastp or Trim Galore here
    // - eval('bash --version | head -1') : runs AFTER the script, captures stdout, also change to Fastp or Trim Galore here
    // - topic: versions        : broadcasts to the shared 'versions' topic
    tuple val("${task.process}"), val('bash'),
          eval('bash --version | head -1 | sed "s/.*version //"'),
          emit: versions_bash, topic: versions

    script:
    // Notice: no versions.yml heredoc here anymore
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
    tuple val(meta), path("${meta.id}.counts.txt"),  emit: counts

    tuple val("${task.process}"), val('awk'),
          eval('awk --version 2>&1 | head -1'),
          emit: versions_awk, topic: versions

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
    path "pipeline_report.txt",  emit: report

    // A process can emit to a topic without also emitting to a named channel.
    // Just omit the emit: label if you don't need the channel downstream.
    tuple val("${task.process}"), val('bash'),
          eval('bash --version | head -1 | sed "s/.*version //"'),
          topic: versions

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

    // ── NEW version collection — subscribe ONCE, get ALL modules automatically ─
    // channel.topic('versions') collects every emission tagged topic: versions
    // from any process in this pipeline — no mix chains needed.
    //
    // IMPORTANT: the process name is included so you can see which step used which tool.
    channel.topic('versions')
        .map { process_name, tool, version ->
            "${process_name} | ${tool}: ${version.trim()}"
        }
        .unique()
        .collectFile(
            name:     'software_versions.txt',
            storeDir: 'results',
            newLine:  true
        )

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
