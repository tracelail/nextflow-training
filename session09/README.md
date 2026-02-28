# Session 9 — Operators Deep Dive: Transforming Data Flows

**Source material:** training.nextflow.io — Fundamentals: Operators + Advanced: Operator Tour  
**2026 syntax enforced throughout:** lowercase `channel.of()`, explicit closure parameters, no implicit `it`

---

## Learning Objectives

By the end of this session you will be able to:

- Use the core transformation operators: `map`, `filter`, `flatten`, `flatMap`
- Aggregate and group data with `collect`, `groupTuple`, and `transpose`
- Merge and split channels with `mix`, `join`, `branch`, and `multiMap`
- Perform a Cartesian scatter with `combine` and re-aggregate with `groupTuple`
- Parse CSV data with `splitCsv` and write output files with `collectFile`
- Implement the **scatter-gather pattern** used in real bioinformatics pipelines

---

## Prerequisites

- Sessions 1–8 complete
- You understand processes, channels, and the `[meta, file]` tuple convention
- Your `nextflow-training` repo is up to date

---

## Concepts

### What operators do

Operators sit between channel sources and processes. They let you reshape, filter, split, and
combine data flows **without writing a process**. Every operator returns a new channel — they
never modify the source channel in place.

```
channel.of(...)  →  .map { ... }  →  .filter { ... }  →  process(ch)
```

### The 2026 syntax rule you must follow everywhere

The strict parser (default from Nextflow 26.04, mandatory in nf-core Q2 2026) **bans the
implicit `it` parameter**. Every closure must name its parameters explicitly:

```nextflow
// ❌ BANNED in strict syntax
ch.map { it.toUpperCase() }

// ✅ CORRECT — always name your parameters
ch.map { word -> word.toUpperCase() }
ch.filter { meta, reads -> meta.type == 'tumor' }
```

### Operators are not functions — they are channel transformations

Unlike a Groovy function that takes a value and returns a value, operators run **asynchronously
on a stream**. The result is a new channel, not a computed value. This is why you chain them
with `.` and pass the result to a process.

---

## Sample Data

All exercises use files in the `data/` directory:

| File | Contents |
|---|---|
| `data/samplesheet.csv` | 6 samples with tumor/normal type, paired FASTQ paths |
| `data/intervals.csv` | 4 genomic intervals for scatter-gather |
| `data/genes.txt` | Simple gene name list for text operator demos |

---

## Exercise 1 — Basic: map, filter, flatten, collect

**Goal:** Practice the four fundamental transformation operators on simple data and on the
samplesheet.

### Step 1: Create the file

Create `exercises/01_basic_operators.nf` with this content:

```nextflow
// exercises/01_basic_operators.nf
// Session 9 — Exercise 1: map, filter, flatten, collect
// Run: nextflow run exercises/01_basic_operators.nf

workflow {

    // ── Part A: map ──────────────────────────────────────────────
    // map transforms each item. The closure receives one item and returns
    // a new item. Always name the closure parameter explicitly.

    ch_numbers = channel.of( 1, 2, 3, 4, 5 )

    ch_numbers
        .map { n -> n * n }
        .view { n -> "Squared: ${n}" }

    // map on a file channel — attach the base name as metadata
    ch_files = channel.fromPath( 'data/*.txt' )

    ch_files
        .map { f -> [f.baseName, f] }
        .view { name, f -> "File: ${name}" }


    // ── Part B: filter ───────────────────────────────────────────
    // filter keeps only items where the closure returns true.

    channel.of( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 )
        .filter { n -> n % 2 == 0 }
        .view { n -> "Even: ${n}" }


    // ── Part C: flatten ──────────────────────────────────────────
    // flatten recursively unpacks nested lists into individual items.
    // NOTE: prefer flatMap for controlled single-level flattening.

    channel.of( [1, 2], [3, [4, 5]], 6 )
        .flatten()
        .view { n -> "Flattened: ${n}" }


    // ── Part D: collect ──────────────────────────────────────────
    // collect waits for ALL items then emits ONE list.
    // The result is a value channel — reusable unlimited times.

    channel.of( 'alpha', 'beta', 'gamma', 'delta' )
        .collect()
        .view { list -> "All words: ${list}" }

}
```

### Step 2: Run it

```bash
nextflow run exercises/01_basic_operators.nf
```

You should see output for each Part (A–D). The order between parts may vary — that is normal,
because Nextflow runs channels concurrently.

**Expected output (order may differ):**
```
Squared: 1
Squared: 4
Squared: 9
Squared: 16
Squared: 25
File: genes
Even: 2
Even: 4
Even: 6
Even: 8
Even: 10
Flattened: 1
Flattened: 2
Flattened: 3
Flattened: 4
Flattened: 5
Flattened: 6
All words: [alpha, beta, gamma, delta]
```

### Step 3: Parse the samplesheet with map

Add this block inside `workflow {}` below your existing code:

```nextflow
    // ── Part E: samplesheet parsing ──────────────────────────────
    // splitCsv with header:true gives you one Map per row.
    // Wrap path strings in file() to get Path objects.

    channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .map { row ->
            def meta = [
                id:   row.sample_id,
                type: row.type
            ]
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }
        .view { meta, fq1, fq2 -> "Sample: ${meta.id} (${meta.type})" }
```

Run again. You should see 6 sample lines.

### Step 4: Filter to tumors only

Chain a `.filter` after your `.map` (before `.view`):

```nextflow
        .filter { meta, fq1, fq2 -> meta.type == 'tumor' }
```

You should now see only 3 tumor samples.

---

## Exercise 2 — Intermediate: branch, join, multiMap, collectFile

**Goal:** Route samples to separate paths with `branch`, reunite outputs with `join`, split
tuples with `multiMap`, and write summary files with `collectFile`.

### Step 1: Create the file

Create `exercises/02_intermediate_operators.nf`:

```nextflow
// exercises/02_intermediate_operators.nf
// Session 9 — Exercise 2: branch, join, multiMap, collectFile
// Run: nextflow run exercises/02_intermediate_operators.nf

workflow {

    // ── Parse samplesheet ────────────────────────────────────────
    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .map { row ->
            def meta = [id: row.sample_id, type: row.type, condition: row.condition]
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }


    // ── Part A: branch ───────────────────────────────────────────
    // branch routes each item to the FIRST matching label.
    // A catch-all `true` is REQUIRED — items with no match are silently dropped.

    ch_samples
        .branch { meta, fq1, fq2 ->
            tumor:  meta.type == 'tumor'
            normal: true            // catch-all — captures everything else
        }
        .set { ch_split }

    ch_split.tumor
        .view { meta, fq1, fq2 -> "TUMOR:  ${meta.id}" }

    ch_split.normal
        .view { meta, fq1, fq2 -> "NORMAL: ${meta.id}" }


    // ── Part B: join ─────────────────────────────────────────────
    // join performs an inner join by default — only items whose key exists
    // in BOTH channels are emitted. Use remainder:true for outer join.

    ch_scores = channel.of(
        [ [id: 'SAMPLE_A'], 42 ],
        [ [id: 'SAMPLE_B'], 87 ],
        [ [id: 'SAMPLE_C'], 61 ]
    )

    ch_flags = channel.of(
        [ [id: 'SAMPLE_A'], 'PASS' ],
        [ [id: 'SAMPLE_B'], 'FAIL' ],
        [ [id: 'SAMPLE_D'], 'PASS' ]   // SAMPLE_C and SAMPLE_D have no match
    )

    // Inner join — SAMPLE_C (no flag) and SAMPLE_D (no score) are dropped
    ch_scores
        .join( ch_flags )
        .view { meta, score, flag -> "Inner join: ${meta.id} score=${score} flag=${flag}" }

    // Outer join — unmatched items appear with null values
    ch_scores
        .join( ch_flags, remainder: true )
        .view { meta, score, flag -> "Outer join: ${meta.id} score=${score} flag=${flag}" }


    // ── Part C: multiMap ─────────────────────────────────────────
    // multiMap sends EVERY item to ALL labeled outputs.
    // Unlike branch (one output per item), multiMap copies to all outputs.

    ch_samples
        .multiMap { meta, fq1, fq2 ->
            meta_only: meta
            reads:     [ meta.id, fq1, fq2 ]
        }
        .set { ch_multi }

    ch_multi.meta_only
        .view { meta -> "Meta:  ${meta.id} (${meta.type})" }

    ch_multi.reads
        .view { id, fq1, fq2 -> "Reads: ${id}" }


    // ── Part D: collectFile ──────────────────────────────────────
    // collectFile collects channel strings and writes them to a file.
    // storeDir persists the file after the pipeline ends.

    ch_samples
        .map { meta, fq1, fq2 -> "${meta.id}\t${meta.type}\t${meta.condition}\n" }
        .collectFile( name: 'sample_summary.tsv', storeDir: 'results' )
        .view { f -> "Written: ${f}" }

}
```

### Step 2: Run it

```bash
nextflow run exercises/02_intermediate_operators.nf
```

**Expected output:**
```
TUMOR:  SAMPLE_A
TUMOR:  SAMPLE_B
TUMOR:  SAMPLE_C
NORMAL: SAMPLE_D
NORMAL: SAMPLE_E
NORMAL: SAMPLE_F
Inner join: SAMPLE_A score=42 flag=PASS
Inner join: SAMPLE_B score=87 flag=FAIL
Outer join: SAMPLE_A score=42 flag=PASS
Outer join: SAMPLE_B score=87 flag=FAIL
Outer join: SAMPLE_C score=61 flag=null
Outer join: SAMPLE_D score=null flag=PASS
Meta:  SAMPLE_A (tumor)
...
Reads: SAMPLE_A
...
Written: .../results/sample_summary.tsv
```

### Step 3: Verify the written file

```bash
cat results/sample_summary.tsv
```

You should see 6 tab-separated lines, one per sample.

---

## Exercise 3 — Challenge: The Scatter-Gather Pattern

**Goal:** Implement the canonical bioinformatics scatter-gather pattern — combine samples ×
intervals, process each combination in parallel, then re-aggregate by sample using `groupTuple`.

This pattern underlies real variant calling pipelines (e.g., GATK HaplotypeCaller per-interval).

### Step 1: Understand the pattern

```
Samples:   [SAMPLE_A], [SAMPLE_B], [SAMPLE_C]   (3 tumor samples)
Intervals: [chr1:1-10000], [chr2:1-10000], [chr3:1-10000], [chrX:1-10000]  (4 intervals)

After combine → 12 items:
  [SAMPLE_A, chr1:1-10000]
  [SAMPLE_A, chr2:1-10000]
  ... (all combinations)
  [SAMPLE_C, chrX:1-10000]

After CALL_VARIANTS → 12 outputs (running in parallel)

After groupTuple → 3 items:
  [SAMPLE_A, [chr1_result, chr2_result, chr3_result, chrX_result]]
  [SAMPLE_B, [...]]
  [SAMPLE_C, [...]]

After MERGE_VCFS → 3 final merged files
```

### Step 2: Create the file

Create `exercises/03_scatter_gather.nf`:

```nextflow
// exercises/03_scatter_gather.nf
// Session 9 — Exercise 3: Scatter-Gather Pattern
// Run: nextflow run exercises/03_scatter_gather.nf

// ── Processes ────────────────────────────────────────────────────────────────

// Simulates per-interval variant calling (the "scatter" step)
process CALL_VARIANTS {
    tag "${meta.id}:${interval}"

    input:
    tuple val(meta), val(interval)

    output:
    tuple val(meta), val("${meta.id}_${interval}.vcf")

    script:
    """
    echo "Calling variants for ${meta.id} on ${interval}"
    """
}

// Simulates merging per-interval VCFs into one (the "gather" step)
process MERGE_VCFS {
    tag "${meta.id}"

    publishDir 'results/merged', mode: 'copy'

    input:
    tuple val(meta), val(vcf_list)

    output:
    tuple val(meta), path("${meta.id}_merged.txt")

    script:
    """
    echo "Merging VCFs for ${meta.id}: ${vcf_list.join(', ')}" > ${meta.id}_merged.txt
    """
}


// ── Workflow ─────────────────────────────────────────────────────────────────

workflow {

    // 1. Load tumor samples only
    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .filter { row -> row.type == 'tumor' }
        .map { row -> [ [id: row.sample_id, type: row.type], row.fastq_1 ] }

    // 2. Load genomic intervals
    ch_intervals = channel.fromPath( 'data/intervals.csv' )
        .splitCsv( header: true )
        .map { row -> row.interval }

    // 3. SCATTER: every sample × every interval
    //    combine with no `by` produces the full Cartesian product
    ch_scattered = ch_samples.combine( ch_intervals )

    ch_scattered.view { meta, fq, interval ->
        "Scattered: ${meta.id} × ${interval}"
    }

    // 4. Run variant calling on each combination in parallel
    //    We drop the fastq path — this process only needs meta + interval
    CALL_VARIANTS( ch_scattered.map { meta, fq, interval -> [meta, interval] } )

    // 5. GATHER: regroup all per-interval results back to one item per sample
    //    groupTuple groups by the first element (meta map) by default
    ch_gathered = CALL_VARIANTS.out
        .groupTuple()

    ch_gathered.view { meta, vcfs ->
        "Gathered ${meta.id}: ${vcfs.size()} VCFs → ${vcfs}"
    }

    // 6. Merge all per-interval VCFs into one file per sample
    MERGE_VCFS( ch_gathered )

    MERGE_VCFS.out.view { meta, merged ->
        "Final: ${meta.id} → ${merged}"
    }
}
```

### Step 3: Run it

```bash
nextflow run exercises/03_scatter_gather.nf
```

**Expected output:**
```
Scattered: SAMPLE_A × chr1:1-10000
Scattered: SAMPLE_A × chr2:1-10000
Scattered: SAMPLE_A × chr3:1-10000
Scattered: SAMPLE_A × chrX:1-10000
Scattered: SAMPLE_B × chr1:1-10000
...  (12 lines total)
Gathered SAMPLE_A: 4 VCFs → [SAMPLE_A_chr1:1-10000.vcf, ...]
Gathered SAMPLE_B: 4 VCFs → [...]
Gathered SAMPLE_C: 4 VCFs → [...]
Final: SAMPLE_A → .../SAMPLE_A_merged.txt
Final: SAMPLE_B → .../SAMPLE_B_merged.txt
Final: SAMPLE_C → .../SAMPLE_C_merged.txt
```

### Step 4: Inspect the execution log

```bash
nextflow log last -f 'process,tag,status,duration'
```

Notice all 12 CALL_VARIANTS tasks listed. They run concurrently — this is the value of scatter.

### Step 5: Add the `size` parameter to groupTuple

Change the groupTuple line to:

```nextflow
    ch_gathered = CALL_VARIANTS.out
        .groupTuple( size: 4 )
```

Re-run with `-resume`. With `size: 4`, each group is emitted as soon as 4 items arrive,
without waiting for the entire channel to close. In large pipelines this prevents downstream
processes from being blocked waiting for a slow final interval.

---

## Debugging Tips

**`groupTuple` hangs forever with no output**  
The most common issue in this session. Without `size`, `groupTuple` waits for the upstream
channel to fully close. If upstream is a value channel (`collect()`, `channel.value()`), it
never closes. Fix: add `size: N` or use `groupKey(meta, N)`.

**`branch` silently drops items**  
Without a catch-all `true` condition at the end of your branch block, items matching no label
are silently discarded. Always end your branch with `other: true` or `rest: true`.

**`join` produces no output**  
The default inner join silently discards unmatched keys. Add `.view()` to both input channels
and confirm keys match exactly. Meta maps must be **identical objects** — `[id:'A']` and
`[id:'A', type:'tumor']` are different keys even though both have `id:'A'`.

**`splitCsv` values are strings, not files**  
`file(row.fastq_1)` is required. Without `file()`, the value is a plain string and the process
receives a literal string path, causing "file not found" errors during staging.

**`combine` produces an unexpectedly large channel**  
Without `by:`, `combine` makes a full Cartesian product. 100 samples × 100 intervals = 10,000
tasks. Verify the expected count first: `ch_scattered.count().view()`.

---

## Key Takeaways

Operators transform channel data between source and process — they are the core of Nextflow's
data-flow model and should be your first tool before reaching for process-level logic. The
`branch` + `join` pair is the workhorse for routing tumor/normal or case/control sample pairs
through independent processing arms and then reuniting them. The scatter-gather pattern
(`combine` → process → `groupTuple`) is the foundational design for parallelising work across
genomic intervals and is used in virtually every production variant calling pipeline.

---

## Operator Quick-Reference

| Operator | In → Out | One-liner |
|---|---|---|
| `map` | 1 → 1 | Transform each item |
| `filter` | 1 → 0–1 | Keep items matching condition |
| `flatten` | 1 → N (recursive) | Unpack all nesting levels |
| `flatMap` | 1 → N (1 level) | Map then flatten one level |
| `collect` | N → 1 | Bundle all items into one list |
| `groupTuple` | N → M | Group tuples sharing a key |
| `join` | 2 ch → 1 | Inner join by key |
| `branch` | 1 → 1 of M | Route to first matching label |
| `multiMap` | 1 → all M | Send every item to all labels |
| `combine` | N × M → N*M | Cartesian cross-product |
| `mix` | M ch → 1 | Merge channels, no order guarantee |
| `transpose` | 1 → N | Unzip grouped tuples |
| `splitCsv` | 1 → N rows | Parse CSV/TSV into records |
| `collectFile` | N → file(s) | Write items to file(s) |
