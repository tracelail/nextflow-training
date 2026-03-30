# Session 19 — Workflow Outputs, Data Lineage, and Advanced Features

## Learning Objectives

After completing this session you will be able to:

- Replace `publishDir` directives with a centralized `output {}` block in the entry workflow
- Enable data lineage tracking and explore provenance records with the `nextflow lineage` CLI
- Collect version information from all modules using topic channels — without any manual channel wiring
- Use the `eval` output qualifier to capture tool version strings directly from the task environment
- Enable Wave for on-demand container provisioning from Conda specs
- Add `onComplete:` and `onError:` handlers to the entry workflow (strict syntax, 25.10+)

---

## Prerequisites

- Sessions 1–18 completed (or comfortable with DSL2 processes, modules, channels, and configuration)
- Nextflow ≥ 25.10.4 installed (`nextflow -version` to verify)
- Docker available and running (`docker info` to verify)
- The `nf-core` conda environment activated

---

## Concepts

### Why workflow outputs replace publishDir

In earlier sessions every process had its own `publishDir` directive telling Nextflow where to copy results. This works but has a problem: publish logic is scattered across dozens of process definitions. If you want to change the output directory, switch from `copy` to `symlink`, or add a file manifest, you must touch every process file.

The **workflow output block** (stable in Nextflow 25.10) moves all publish decisions into one place — the entry workflow. Processes no longer know or care where their outputs go. The workflow assigns channels to named outputs in a `publish:` section, and a separate top-level `output {}` block declares how each named output is stored on disk.

### How topic channels eliminate version wiring

The old nf-core pattern for collecting tool versions required every module to write a `versions.yml` file, and every subworkflow to run `ch_versions = ch_versions.mix(MODULE.out.versions.first())` after every single module call. For a pipeline with 20 modules that is 20 lines of boilerplate, all of which breaks if you forget one.

Topic channels solve this with zero wiring. Any process output line can carry `topic: versions` (or any topic name). The framework collects those emissions into a shared channel automatically. The workflow subscribes once with `channel.topic('versions')` and gets everything — no mix chains required.

### Data lineage

When `lineage.enabled = true` is set in config, Nextflow writes JSON provenance records into a `.lineage/` directory for every workflow run, every task, and every published output file. Each record has a **Lineage ID (LID)** — a content-addressed URI — you can query, inspect, diff, and render as an interactive graph. The data model is `v1beta1` (experimental as of early 2026), meaning the schema may change, but the feature is stable enough to use.

### eval output qualifier

`eval('shell command')` in a process `output:` block runs a shell command **after** the task script completes, inside the same container or environment, and captures its stdout as a string value. The primary use is capturing tool version strings without writing a file.

---

## Exercises

### Exercise 1 — Basic: Replace publishDir with a workflow output block

**Step 1.** Look at the starting pipeline. It has three processes, each with `publishDir`.

```bash
cat ex1_publishdir.nf
```

Notice that publish logic is in three different places and they all use slightly different options.

**Step 2.** Create a new file `ex1_workflow_output.nf` that moves all publishing to a single `output {}` block.

```bash
cp ex1_publishdir.nf ex1_workflow_output.nf
```

Open `ex1_workflow_output.nf` and make these changes:

- Remove the `publishDir` line from every process
- Add a `publish:` section to the entry workflow
- Add a top-level `output {}` block after the workflow

The publish section uses `=` assignment (NOT `>>`):

```nextflow
workflow {
    main:
    // ... existing logic ...

    publish:
    trimmed    = TRIM.out.reads
    counts     = COUNT.out.counts
    summary    = SUMMARISE.out.report
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
```

**Step 3.** Run it:

```bash
nextflow run ex1_workflow_output.nf
```

You should see a `results/` directory with three subdirectories: `trimmed/`, `counts/`, and one file at the root.

**Step 4.** Change the copy mode in `nextflow.config`:

```groovy
workflow.output.mode = 'symlink'
```

Re-run with `-resume` and observe that the `results/` files are now symlinks.

---

### Exercise 2 — Intermediate: Enable data lineage and explore records

**Step 1.** Add lineage to `nextflow.config`:

```groovy
lineage {
    enabled = true
}
```

**Step 2.** Run the pipeline from Exercise 1:

```bash
nextflow run ex1_workflow_output.nf
```

**Step 3.** Look at what was created:

```bash
ls -la .lineage/
```

You will see a directory of JSON files. Each file is a provenance record.

**Step 4.** List all tracked runs:

```bash
nextflow lineage list
```

You will see output like:

```
lid://abc123...    2026-03-15 10:23:44    my_pipeline    COMPLETED
```

**Step 5.** View the workflow run record:

```bash
nextflow lineage view lid://<paste the LID from list>
```

Read the JSON. Find the `parameters` and `scriptFiles` fields.

**Step 6.** View a specific output file's provenance. The LID for a published file is the workflow LID plus the relative path:

```bash
nextflow lineage view lid://<workflow LID>/results/counts/sampleA.counts.txt
```

This shows the file's checksum, which task produced it, and what inputs that task consumed.

**Step 7.** Render an interactive lineage graph:

```bash
nextflow lineage render lid://<workflow LID>/results/summary/pipeline_report.txt
```

This opens (or writes) an HTML file showing the data flow from input through every task to this output file.

---

### Exercise 3 — Challenge: Topic channels for version collection + eval

This exercise replaces the old `versions.yml` pattern in `ex3_versions_old.nf` with topic channels.

**Step 1.** Read the old approach:

```bash
cat ex3_versions_old.nf
```

Notice each process writes a `versions.yml` file and the workflow mixes them all manually.

**Step 2.** Create `ex3_versions_topic.nf`. For each process, make these changes:

Remove:
```nextflow
path "versions.yml", emit: versions
```

Remove from the script block:
```bash
cat <<-END_VERSIONS > versions.yml
"${task.process}":
    toolname: $(toolname --version 2>&1)
END_VERSIONS
```

Add (in the output block):
```nextflow
tuple val("${task.process}"), val('toolname'),
      eval('toolname --version 2>&1 | head -1'),
      emit: versions_toolname, topic: versions
```

**Step 3.** In the workflow, remove all the `ch_versions.mix(...)` lines and the `ch_versions = Channel.empty()` initialiser.

Replace the version collection at the end of the workflow with:

```nextflow
channel.topic('versions')
    .map { process_name, tool, version ->
        "${tool}: ${version.trim()}"
    }
    .unique()
    .collectFile(name: 'software_versions.txt', newLine: true, storeDir: 'results')
```

**Step 4.** Run and verify:

```bash
nextflow run ex3_versions_topic.nf
cat results/software_versions.txt
```

You should see version strings for every tool — collected automatically, with no mix chains.

---

## Debugging Tips

**1. "nextflow.preview.output is not a valid config property"**
You have the old preview flag in your `nextflow.config`. Remove `nextflow.preview.output = true` entirely — it must not be present in 25.10+.

**2. publish: uses `>>` and nothing is published**
The `>>` operator was the 24.04 preview syntax. In 25.10+ the `publish:` section uses `=` assignment. Change `ch_fastqc >> 'fastqc'` to `fastqc = FASTQC.out.html`.

**3. Lineage records are empty / no FileOutput records appear**
Data lineage only tracks files published via the workflow `output {}` block. Files published with `publishDir` in processes do NOT generate lineage records. You must use the workflow output system for lineage to work end-to-end.

**4. Pipeline hangs when using topic channels**
A process that consumes a topic channel must not also emit to that same topic. Check that no process in your channel.topic('versions') consumption chain emits back to the versions topic.

**5. eval command fails / task fails unexpectedly**
The `eval` command runs in the task container after the script. If the tool is not on PATH in that container the task will fail. Append `|| true` if the version command returns a non-zero exit code: `eval('toolname --version 2>&1 || true')`.

**6. "workflow output block only allowed in entry workflow"**
The `publish:` section and `output {}` block can only appear in the entry (unnamed) workflow. Named sub-workflows use `emit:` as before.

---

## Key Takeaways

The workflow `output {}` block centralises all publish decisions in one place, separating pipeline logic from data delivery and making it easy to change output structure without touching any process. Topic channels eliminate the manual version-mix boilerplate that clutters nf-core pipelines, letting any module emit provenance data that the framework collects automatically. Data lineage provides content-addressed provenance for every published file, enabling reproducibility audits and diff-based debugging between pipeline runs.
