# Session 19 — Quick Reference Card

## Workflow output block (25.10 stable)

```nextflow
workflow {
    main:
    PROCESS_A(input_ch)
    PROCESS_B(PROCESS_A.out.files)

    publish:                           // assignment = , NOT >>
    processed = PROCESS_A.out.files
    results   = PROCESS_B.out.report
}

output {                               // top-level, outside the workflow block
    processed {
        path 'processed'               // → results/processed/
    }
    results {
        path '.'                       // → results/ (root)
    }
}
```

**In nextflow.config:**
```groovy
workflow.output.mode = 'copy'          // 'symlink' (default), 'copy', 'move'
// Output dir defaults to 'results/'; override with -output-dir on CLI
```

**⚠️ Remove this if upgrading from preview:**
```groovy
// nextflow.preview.output = true    ← DELETE THIS LINE in 25.10+
```

---

## Data lineage

**Enable in nextflow.config:**
```groovy
lineage {
    enabled = true
}
```

**CLI commands:**
```bash
nextflow lineage list
nextflow lineage view lid://<LID>
nextflow lineage view lid://<LID>/results/path/to/file.txt
nextflow lineage render lid://<LID>/results/path/to/file.txt
nextflow lineage find type=TaskRun
nextflow lineage diff lid://<LID1> lid://<LID2>
```

**⚠️ Only files published via the output{} block appear in lineage records.**
Files published with publishDir in processes are NOT tracked.

---

## Topic channels

**In a process output block:**
```nextflow
output:
tuple val(meta), path("*.bam"),       emit: bam
tuple val("${task.process}"), val('samtools'),
      eval('samtools --version | head -1'),
      emit: versions_samtools, topic: versions
```

**Consuming in the workflow:**
```nextflow
channel.topic('versions')             // returns a queue channel
    .map { process_name, tool, version ->
        "${tool}: ${version.trim()}"
    }
    .unique()
    .collectFile(name: 'versions.txt', storeDir: 'results', newLine: true)
```

**⚠️ Never consume a topic inside a process that also emits to that topic → pipeline hangs.**

---

## eval output qualifier

```nextflow
output:
tuple val(meta), path("*.sorted.bam"),         emit: bam
eval('samtools --version | head -1'),           emit: version_str
```

- Runs AFTER the script completes, in the same container/environment
- Captures stdout as a string
- Use `|| true` if the tool returns non-zero exit code from --version

---

## Wave (conceptual — requires Seqera Platform account)

```groovy
// nextflow.config
wave {
    enabled  = true
    strategy = ['conda']    // build container from process conda: directive
}
```

```nextflow
process MY_PROCESS {
    conda 'bioconda::bwa=0.7.18'   // Wave builds a container from this spec
    // or
    conda '/path/to/environment.yml'

    script: ...
}
```

---

## onComplete / onError handlers

**Style A — classic (all versions):**
```nextflow
// Outside the workflow block
workflow.onComplete {
    println "Status: ${workflow.success ? 'OK' : 'FAILED'}"
    println "Duration: ${workflow.duration}"
}

workflow.onError {
    println "Error: ${workflow.errorMessage}"
}
```

**Style B — section syntax (25.10+ with NXF_SYNTAX_PARSER=v2):**
```nextflow
workflow {
    main: ...
    publish: ...

    onComplete:
    println "Status: ${workflow.success ? 'OK' : 'FAILED'}"

    onError:
    println "Error: ${workflow.errorMessage}"
}
```

---

## Common workflow properties in handlers

| Property | Description |
|---|---|
| `workflow.success` | Boolean: true if completed without errors |
| `workflow.duration` | Human-readable duration string |
| `workflow.complete` | Completion timestamp |
| `workflow.errorMessage` | Short error description |
| `workflow.errorReport` | Full error stack trace |
| `workflow.launchDir` | Directory where nextflow was run |
| `workflow.workDir` | Work directory path |
| `workflow.runName` | Auto-generated run name |
| `workflow.sessionId` | UUID for this run (stable across -resume) |
