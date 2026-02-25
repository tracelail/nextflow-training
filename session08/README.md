# Session 8 — The Meta Map Pattern: Metadata-Driven Pipelines

**Source material:** [Metadata in Workflows (training.nextflow.io)](https://training.nextflow.io/2.8.1/side_quests/metadata/) | [Essential Scripting Patterns](https://training.nextflow.io/2.8.1/side_quests/essential_scripting_patterns/)

---

## Learning objectives

By the end of this session you will be able to:

- Explain why the `[meta, reads]` tuple convention exists and what problem it solves
- Parse a CSV samplesheet into structured `[meta, reads]` channel tuples using `splitCsv(header: true)` and `.map`
- Propagate metadata through multiple chained processes without losing or corrupting it
- Safely augment a meta map mid-pipeline using `meta + [key: value]` (and explain why you must never modify a map in-place)
- Handle missing or optional CSV fields gracefully using the `?.` and `?:` operators
- Use meta values to dynamically control `publishDir` paths and process behavior

---

## Prerequisites

- Sessions 1–7 completed
- Nextflow 25.04.6 installed and working (`nextflow -version`)
- The `data/` directory present with `samplesheet.csv` and `reads/` folder

---

## Concepts

### Why the meta map exists

Imagine you have a CSV samplesheet with 4 columns. Without the meta map pattern your channel tuple might look like this:

```groovy
// Fragile: hard-coded column positions
tuple val(id), val(condition), val(replicate), path(reads)
```

Add a fifth column and every single process in your pipeline breaks. The meta map pattern solves this by putting **all metadata into one Groovy map** and keeping **files as the second tuple element**:

```groovy
// Robust: shape never changes no matter how many metadata columns you add
tuple val(meta), path(reads)
```

`meta` is just a Groovy `Map` — a collection of key/value pairs: `[id: 'CTRL_1', condition: 'control', replicate: '1']`. You access fields with dot notation: `meta.id`, `meta.condition`.

**The `id` field is mandatory by nf-core convention.** It is used for output file naming, process log tagging, and as the join key when combining channels.

### How data flows: the [meta, reads] contract

Every nf-core process declares its inputs and outputs as:

```groovy
input:
tuple val(meta), path(reads)   // or path(bam), path(vcf), etc.

output:
tuple val(meta), path("${meta.id}.result.txt")
```

`meta` is declared as `val` (a value, not a file). Nextflow passes it through as-is. Because both input and output include `val(meta)`, the metadata travels with the data through every step automatically.

### Augmenting meta maps: always use `+`

After a process runs you often want to add a new field to meta. The **only safe way** to do this is:

```groovy
// CORRECT — creates a completely new map object
def new_meta = meta + [read_count: 42]

// WRONG — mutates the shared original object
// meta.read_count = 42   ← DO NOT DO THIS
```

Why does mutation cause problems? In Nextflow, the same meta object can be referenced by multiple parallel operations at the same time. Mutating it in one branch changes what other branches see — a race condition that produces unpredictable results. The `+` operator always creates a fresh map, so each operation gets its own independent copy.

### Null-safe operators

CSV files often have optional columns. Two Groovy operators handle this gracefully:

| Operator | Name | Behaviour |
|---|---|---|
| `?.` | Safe navigation | Returns `null` instead of crashing when called on a `null` value |
| `?:` | Elvis | Returns the right side when the left side is `null` or falsy |

Combined pattern:

```groovy
// If row.strandedness is empty/null: return 'unstranded' instead of crashing
def strandedness = row.strandedness?.trim() ?: 'unstranded'
```

---

## Exercise 1 — Basic: Parse a samplesheet (≈ 10 min)

**What you will do:** Read a CSV, inspect the raw rows, then reshape them into `[meta, reads]` tuples.

### Step 1: Look at your samplesheet

```bash
cat data/samplesheet.csv
```

You should see six samples with columns: `sample_id, condition, replicate, single_end, strandedness, fastq_1, fastq_2`.

### Step 2: Run the exercise

```bash
nextflow run exercise1_parse_csv.nf
```

### Step 3: Read the output carefully

You will see two sets of output:

1. **RAW ROW** lines — this is what `splitCsv(header: true)` gives you before any transformation. Each row is a Groovy map where column headers are the keys.

2. **SAMPLE / READS** blocks — this is after `.map { row -> ... }` has restructured each row into `[meta, reads]`.

### Step 4: Understand the key line

Find this in `exercise1_parse_csv.nf`:

```groovy
def reads = [ file(row.fastq_1), file(row.fastq_2) ]
```

**Why `file()`?** `row.fastq_1` is a plain string like `"data/reads/CTRL_1_R1.fastq"`. Nextflow processes with `path(reads)` inputs need a `Path` object, not a string. Omitting `file()` causes the error: `No such file or directory`. Always wrap CSV file columns with `file()`.

### Step 5: Modify it

Open `exercise1_parse_csv.nf` and add `tissue_type: 'unknown'` as a new field in the meta map. Re-run. Confirm the new field appears in the view output.

---

## Exercise 2 — Intermediate: Propagate and augment meta (≈ 20 min)

**What you will do:** Chain three operations — a channel operator (parse) and two processes (count, report) — and augment the meta map between steps.

### Step 1: Run the exercise

```bash
nextflow run exercise2_propagate_meta.nf
```

### Step 2: Observe meta propagation

Watch the **ENRICHED META** lines in the output. The `read_count` field was not in the original CSV — it was computed by `COUNT_READS` and added to meta via `.map { meta, reads, count_str -> meta + [read_count: ...] }`.

### Step 3: Inspect the reports

```bash
cat results/reports/CTRL_1_report.txt
```

You should see all the meta fields including `read_count` written into the report.

### Step 4: Trace how meta crosses the process boundary

Open `exercise2_propagate_meta.nf`. Find the `COUNT_READS` process. Notice:

```groovy
output:
tuple val(meta), path(reads), stdout
```

The process didn't change `meta` at all — it just declared it in both `input:` and `output:`. That's all it takes. Nextflow passes `meta` through unchanged.

### Step 5: Find and understand the augmentation

Find this block in the workflow:

```groovy
ch_with_count = ch_counted
    .map { meta, reads, count_str ->
        def read_count = count_str.trim().toInteger()
        def new_meta = meta + [read_count: read_count]
        [ new_meta, reads ]
    }
```

The `.trim()` removes the trailing newline that `stdout` capture adds. `.toInteger()` converts the string `"8"` to the number `8`. Then `meta + [read_count: read_count]` produces a new map.

### Challenge extension

Add a second computed field `condition_replicate` that combines condition and replicate into a single string like `"control_rep1"`. Use `meta + [condition_replicate: "${meta.condition}_rep${meta.replicate}"]`. Verify it appears in the report file.

---

## Exercise 3 — Challenge: Null-safe handling and dynamic paths (≈ 25 min)

**What you will do:** Handle a messy samplesheet with missing fields, compute conditional meta values, and route outputs to different directories based on metadata.

### Step 1: Inspect the messy samplesheet

```bash
cat data/samplesheet_missing_fields.csv
```

Notice that `CTRL_3` has an empty `replicate` and `strandedness`. `TREAT_3` has an empty `replicate`, empty `strandedness`, `single_end=true`, and no `fastq_2`.

### Step 2: Run the exercise

```bash
nextflow run exercise3_null_safe.nf
```

### Step 3: Verify defaults were applied

In the view output, confirm:
- `CTRL_3` shows `replicate=unknown` and `strand=unstranded` (not empty/null)
- `TREAT_3` shows `single=true` and `n_files=1` (not 2)

### Step 4: Inspect the output directory structure

```bash
find results -name "*.txt" | sort
```

You should see outputs organized under `results/control/` and `results/treatment/` — driven entirely by `meta.condition`, with no hard-coded paths in the workflow.

### Step 5: Understand the `parseSamplesheet` function

Open `exercise3_null_safe.nf` and read the `parseSamplesheet` function. Focus on this pattern:

```groovy
def replicate = row.replicate?.trim() ?: 'unknown'
```

Trace through what happens for CTRL_3 where `replicate` is empty:
1. `row.replicate` → `""` (empty string)
2. `?.trim()` → `""` (safe call on non-null, returns empty string)
3. `?: 'unknown'` → `'unknown'` (empty string is falsy in Groovy)

### Step 6: Modify the tier logic

Add a `size_tier` field to meta based on `reads.size()`:
- 2 files → `'paired'`
- 1 file → `'single'`

Use `meta + [size_tier: reads.size() == 2 ? 'paired' : 'single']` after the reads list is built. Then modify the `publishDir` in `QC_SUMMARY` to also include the size_tier: `"results/${meta.condition}/${meta.size_tier}/${meta.id}"`.

---

## Exercise 4 — Full Pipeline Demo (run and explore)

**What you will do:** Run the complete pipeline that chains all Session 8 concepts together.

### Step 1: Run it

```bash
nextflow run full_pipeline.nf
```

### Step 2: Explore the results

```bash
find results -name "*.txt" | sort
cat results/control/standard/CTRL_1_final_report.txt
```

### Step 3: Trace the meta enrichment through the pipeline

The pipeline has three augmentation steps. Find them in `full_pipeline.nf`:

1. After `COUNT_READS`: adds `read_count`
2. After a `.map` in the workflow: adds `quality_tier` using a ternary chain
3. The `quality_tier` then drives the `publishDir` in `FINAL_REPORT`

### Step 4: Test -resume

Modify the quality tier threshold (change `> 20` to `> 5`). Re-run with `-resume`:

```bash
nextflow run full_pipeline.nf -resume
```

Which processes were cached? Which re-ran? Why?

---

## Debugging tips

**Error: `No such file or directory` inside a process**

Most likely cause: you forgot to wrap a CSV path with `file()`. Change `row.fastq_1` to `file(row.fastq_1)` in your `.map` closure.

**Error: `Cannot invoke method X() on null object`**

A CSV field is empty and you called a method on it without `?.`. Add the safe navigation operator: `row.field?.method()`.

**Meta field appears as `null` in process script**

The field was added to meta in one branch but the process received the old meta from a different branch. Check that you're returning `new_meta` (not `meta`) from your `.map` closure after augmentation.

**`stdout` capture has unexpected content (extra newline)**

Always call `.trim()` on stdout values before further processing: `count_str.trim().toInteger()`.

**`publishDir` path contains `null`**

A meta field used in the path string is `null`. Add an Elvis default: `meta.condition ?: 'unknown'`.

**Process runs but output file is missing from results/**

Check that `publishDir` is configured and that `mode: 'copy'` is set. The default mode is `symlink`, which can break if the work directory is on a different filesystem.

---

## Key takeaways

The meta map pattern separates metadata from data in a single `[meta, reads]` tuple, making pipelines resilient to samplesheet changes and enabling per-sample behaviour without duplicating process definitions. Meta maps must always be augmented using `meta + [key: value]` to create a new object — never modified in place — because Nextflow may reference the same object from multiple parallel operations simultaneously. The `?.` and `?:` operators are essential production tools for handling the real-world messiness of CSV samplesheets where optional fields are often empty or absent.

---

## Reference: meta map quick guide

```groovy
// Parse CSV → [meta, reads]
channel.fromPath("samplesheet.csv")
    .splitCsv(header: true)
    .map { row ->
        def meta  = [id: row.sample_id, condition: row.condition]
        def reads = [file(row.fastq_1), file(row.fastq_2)]
        [meta, reads]
    }

// Propagate meta through a process (no change needed in the process itself)
process MY_PROCESS {
    input:  tuple val(meta), path(reads)
    output: tuple val(meta), path("${meta.id}.out")
    script: "touch ${meta.id}.out"
}

// Augment meta SAFELY after a process
.map { meta, reads, extra_output ->
    [meta + [new_field: extra_output.trim()], reads]
}

// Null-safe CSV field with default
def value = row.optional_field?.trim() ?: 'default'

// Dynamic publishDir from meta
publishDir "results/${meta.condition}/${meta.id}", mode: 'copy'

// Tag processes in logs with sample ID
tag "${meta.id}"
```

---

## What's next

Session 9 covers operators in depth: `groupTuple`, `join`, `branch`, `combine`, `flatMap`, and the scatter-gather pattern. The meta map's `id` field becomes critical there — it is the key that `join` uses to correctly pair results from different processes.
