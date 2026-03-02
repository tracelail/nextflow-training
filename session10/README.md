# Session 10 — Splitting and Grouping: Scatter-Gather Patterns

**Source material:** [Splitting and Grouping Side Quest](https://training.nextflow.io/latest/side_quests/splitting_and_grouping/) | [Grouping and Splitting Advanced](https://training.nextflow.io/2.1/advanced/grouping/) | [Operator Reference](https://www.nextflow.io/docs/stable/reference/operator.html)

---

## Learning Objectives

After completing this session you will be able to:

- Split a channel two ways — `filter` for simple boolean selection and `branch` for multi-way routing in a single pass
- Join outputs from different processes back together by a shared key using `join`, including outer-join behaviour with `remainder: true`
- Aggregate parallel results into groups using `groupTuple`, and use `groupKey` to avoid pipeline stalls
- Scatter data across a grid of inputs using `combine` to create Cartesian products
- Reconstruct individual tuples from grouped lists using `transpose`
- Wire these operators together into a complete scatter-gather workflow

---

## Prerequisites

- Sessions 1–9 completed
- You should have a `nextflow-training/` GitHub repository
- Comfortable with: `map`, `filter`, `branch`, `collect`, meta maps, `[meta, file]` tuple convention

---

## Concepts

### The scatter-gather idea

Many real pipelines follow this shape:

```
one sample → scatter across N intervals → process N chunks in parallel → gather → merge
```

Nextflow handles parallelism automatically — if a channel has 12 items, 12 tasks can run at once. The operators in this session give you precise control over how data is split apart and reassembled.

### filter vs branch

`filter` keeps items that pass a boolean test and silently drops the rest. If you need two separate streams you call `filter` twice, which means each item is evaluated twice.

`branch` routes each item to exactly one named sub-channel in a single pass. It is more efficient and cleaner when you need multiple output streams from one input.

### join — pairing channels by key

`join` works like a database inner join. It matches tuples from two channels whose first element (the key) is equal, then combines them into one tuple. Items with no match in the other channel are discarded by default.

### groupTuple — the "gather" step

After scattering work across many tasks, you need to collect all results for the same sample back together. `groupTuple` does this. **Without the `size` parameter it waits for every item in the entire pipeline before emitting anything** — this can stall or deadlock large pipelines. Use `groupKey()` or `size:` whenever you know the expected group size.

### combine — the "scatter" step

`combine` produces the Cartesian product of two channels. Four samples combined with three intervals gives twelve tasks. This is how you fan work out across a grid.

### transpose — inverse of groupTuple

If `groupTuple` turns `[key, a], [key, b]` into `[key, [a, b]]`, then `transpose` turns `[key, [a, b]]` back into `[key, a], [key, b]`. Useful when you receive pre-grouped data and need to expand it.

---

## Hands-on Exercises

Work through the three numbered scripts in order. Each one builds on the last.

### Exercise 1 (Basic) — filter and branch

**Goal:** Understand the difference between `filter` and `branch` for splitting a channel.

**Step 1:** Create the file `exercise1_split.nf`:

```nextflow
// exercise1_split.nf
// Demonstrates: filter vs branch for splitting channels
// 2026 syntax: lowercase channel, explicit closure params

workflow {

    // A channel of sample metadata maps
    ch_samples = channel.of(
        [id: 'sampleA', type: 'tumor',  depth: 50],
        [id: 'sampleB', type: 'normal', depth: 40],
        [id: 'sampleC', type: 'tumor',  depth: 35],
        [id: 'sampleD', type: 'normal', depth: 60],
        [id: 'sampleE', type: 'tumor',  depth: 20]
    )

    // ── APPROACH 1: filter ──────────────────────────────────────────
    // filter keeps items that pass the test; others are silently dropped.
    // We call filter TWICE to get two separate streams.

    ch_tumor_filter  = ch_samples.filter { meta -> meta.type == 'tumor'  }
    ch_normal_filter = ch_samples.filter { meta -> meta.type == 'normal' }

    log.info "=== Using filter ==="
    ch_tumor_filter .view { meta -> "  TUMOR  (filter): ${meta.id}" }
    ch_normal_filter.view { meta -> "  NORMAL (filter): ${meta.id}" }

    // ── APPROACH 2: branch ──────────────────────────────────────────
    // branch routes each item ONCE to the first matching sub-channel.
    // The final 'true:' acts as a catch-all so nothing is lost.

    ch_samples
        .branch { meta ->
            tumor:  meta.type == 'tumor'
            normal: meta.type == 'normal'
            other:  true          // catch-all — items matching nothing above land here
        }
        .set { ch_branched }

    log.info "=== Using branch ==="
    ch_branched.tumor .view { meta -> "  TUMOR  (branch): ${meta.id}" }
    ch_branched.normal.view { meta -> "  NORMAL (branch): ${meta.id}" }

    // ── DEEP ENOUGH challenge: filter on a computed value ────────────
    // Only keep high-depth samples (depth >= 40)
    ch_high_depth = ch_samples.filter { meta -> meta.depth >= 40 }
    log.info "=== High-depth samples (depth >= 40) ==="
    ch_high_depth.view { meta -> "  HIGH DEPTH: ${meta.id} depth=${meta.depth}" }
}
```

**Step 2:** Run it:

```bash
nextflow run exercise1_split.nf
```

**You should see** both the tumor and normal samples printed for each approach. Notice that `filter` evaluates every item twice (once per filter call), while `branch` evaluates each item once.

**Now try this modification:** Add a second `branch` criterion that also filters by depth:

```nextflow
ch_samples
    .branch { meta ->
        high_tumor:  meta.type == 'tumor'  && meta.depth >= 40
        low_tumor:   meta.type == 'tumor'  && meta.depth <  40
        normal:      meta.type == 'normal'
        other:       true
    }
    .set { ch_branched2 }

ch_branched2.high_tumor.view { meta -> "HIGH TUMOR: ${meta.id}" }
ch_branched2.low_tumor .view { meta -> "LOW  TUMOR: ${meta.id}" }
```

**Expected:** `sampleA` and `sampleC` should separate into high and low tumor groups.

---

### Exercise 2 (Intermediate) — join and groupTuple

**Goal:** Split tumor/normal samples, process them through separate processes, then rejoin by sample ID.

**Step 1:** Create `exercise2_join.nf`:

```nextflow
// exercise2_join.nf
// Demonstrates: branch → separate processes → join by key → groupTuple
// 2026 syntax: lowercase channel, explicit closure params

// ── Simulated processes ─────────────────────────────────────────────────────
// These write toy output files so we can see real file flow.

process PROCESS_TUMOR {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_tumor.txt")

    script:
    """
    echo "Tumor result for ${meta.id}" > ${meta.id}_tumor.txt
    """
}

process PROCESS_NORMAL {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_normal.txt")

    script:
    """
    echo "Normal result for ${meta.id}" > ${meta.id}_normal.txt
    """
}

process COMBINE_PAIR {
    tag "${meta.id}"
    publishDir "results/pairs", mode: 'copy'

    input:
    tuple val(meta), path(tumor_result), path(normal_result)

    output:
    tuple val(meta), path("${meta.id}_combined.txt")

    script:
    """
    cat ${tumor_result} ${normal_result} > ${meta.id}_combined.txt
    echo "Combined for ${meta.id}" >> ${meta.id}_combined.txt
    """
}

// ── Workflow ────────────────────────────────────────────────────────────────

workflow {

    // Build channel from samplesheet CSV
    ch_samples = channel
        .fromPath("data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, type: row.type]
            def reads = file(row.fastq)
            [meta, reads]
        }

    // Split into tumor and normal streams
    ch_samples
        .branch { meta, reads ->
            tumor:  meta.type == 'tumor'
            normal: meta.type == 'normal'
            other:  true
        }
        .set { ch_branched }

    // Process each stream independently
    PROCESS_TUMOR(ch_branched.tumor)
    PROCESS_NORMAL(ch_branched.normal)

    // ── join: pair tumor and normal results by sample ID ────────────
    // join matches on the first element (meta map).
    // IMPORTANT: the meta maps must be IDENTICAL for join to match them.
    // Here both tumor and normal have the SAME id but DIFFERENT type fields,
    // so we strip the type before joining.

    ch_tumor_keyed  = PROCESS_TUMOR.out
        .map { meta, file -> [ [id: meta.id], file ] }

    ch_normal_keyed = PROCESS_NORMAL.out
        .map { meta, file -> [ [id: meta.id], file ] }

    ch_joined = ch_tumor_keyed.join(ch_normal_keyed)
    // ch_joined now has: [ [id:...], tumor_file, normal_file ]

    COMBINE_PAIR(ch_joined)

    COMBINE_PAIR.out.view { meta, file ->
        "PAIRED RESULT: ${meta.id} → ${file}"
    }

    // ── join with remainder: true (outer join) ───────────────────────
    // What if we had an unpaired sample? remainder: true keeps it with null.
    ch_extra = channel.of( [[id: 'sampleX'], file('data/extra.fastq')] )
    ch_tumor_keyed
        .mix(ch_extra)
        .join(ch_normal_keyed, remainder: true)
        .view { meta, tumor, normal ->
            "OUTER JOIN: ${meta.id}  tumor=${tumor}  normal=${normal}"
        }
}
```

**Step 2:** Run it:

```bash
nextflow run exercise2_join.nf
```

**You should see** each patient's tumor and normal results joined together. The outer join view will show `sampleX` with `normal=null`.

**Key concept to observe:** The `join` on meta maps requires the maps to be **exactly equal** — same keys, same values. That's why we strip `type` before joining (`[id: meta.id]`). If the maps don't match, items are silently dropped (or kept with `null` if `remainder: true`).

---

### Exercise 3 (Challenge) — Full scatter-gather with combine and groupTuple

**Goal:** Scatter four samples across three genomic intervals, process each combination, then gather results per sample using `groupTuple` and `groupKey`.

**Step 1:** Create `exercise3_scatter_gather.nf`:

```nextflow
// exercise3_scatter_gather.nf
// Demonstrates: combine (scatter) → process → groupTuple (gather)
// This mimics real variant calling: each sample × each interval in parallel,
// then all interval results per sample merged back together.
// 2026 syntax: lowercase channel, explicit closure params

// ── Processes ───────────────────────────────────────────────────────────────

process ALIGN {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.bam")

    script:
    """
    # Simulate alignment — just create a placeholder BAM
    echo "Aligned reads for ${meta.id}" > ${meta.id}.bam
    """
}

process GENOTYPE_INTERVAL {
    tag "${meta.id}:${interval}"

    input:
    tuple val(meta), path(bam), val(interval)

    output:
    // groupKey tells Nextflow how many results to expect per sample
    // so groupTuple can emit as soon as a group is complete
    tuple val(groupKey(meta, meta.num_intervals)), path("${meta.id}.${interval}.vcf")

    script:
    """
    echo "Genotyped ${meta.id} on interval ${interval}" > ${meta.id}.${interval}.vcf
    """
}

process MERGE_VCFS {
    tag "${meta.id}"
    publishDir "results/vcfs", mode: 'copy'

    input:
    // After groupTuple: meta is a groupKey object — use .target to get the plain map
    tuple val(meta), path("input/chunk_*.vcf")

    output:
    tuple val(meta), path("${meta.id}.merged.vcf")

    script:
    """
    cat input/chunk_*.vcf > ${meta.id}.merged.vcf
    echo "Merged ${meta.id}" >> ${meta.id}.merged.vcf
    """
}

// ── Workflow ────────────────────────────────────────────────────────────────

workflow {

    // ── Inputs ──────────────────────────────────────────────────────
    ch_samples = channel
        .fromPath("data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, type: row.type]
            def reads = file(row.fastq)
            [meta, reads]
        }

    // Genomic intervals to scatter across (these would be BED files in a real pipeline)
    ch_intervals = channel.of('chr1', 'chr2', 'chr3')

    // ── Step 1: Align each sample ────────────────────────────────────
    ALIGN(ch_samples)

    // ── Step 2: Scatter — combine each BAM with every interval ───────
    // combine produces: [meta, bam, interval] for EVERY sample×interval pair
    // 4 samples × 3 intervals = 12 tasks run in parallel
    ch_scattered = ALIGN.out
        .combine(ch_intervals)
        .map { meta, bam, interval ->
            // Add num_intervals so groupKey knows when each group is complete
            def new_meta = meta + [num_intervals: 3]
            [new_meta, bam, interval]
        }

    ch_scattered.view { meta, bam, interval ->
        "SCATTERED: ${meta.id} × ${interval}"
    }

    // ── Step 3: Process each sample×interval combination ─────────────
    GENOTYPE_INTERVAL(ch_scattered)

    // ── Step 4: Gather — groupTuple collects all intervals per sample ─
    // groupKey (set in GENOTYPE_INTERVAL output) tells groupTuple to emit
    // as soon as 3 results arrive for a sample — no waiting for the whole pipeline.
    ch_gathered = GENOTYPE_INTERVAL.out
        .groupTuple()
        .map { meta_key, vcfs ->
            // Unwrap groupKey to get back the plain meta map
            [meta_key.target, vcfs]
        }

    ch_gathered.view { meta, vcfs ->
        "GATHERED: ${meta.id} — ${vcfs.size()} VCF chunks"
    }

    // ── Step 5: Merge all interval VCFs per sample ───────────────────
    MERGE_VCFS(ch_gathered)

    MERGE_VCFS.out.view { meta, merged ->
        "FINAL: ${meta.id} (${meta.type}) → ${merged}"
    }
}
```

**Step 2:** Run it:

```bash
nextflow run exercise3_scatter_gather.nf
```

**You should see:**

1. `SCATTERED:` lines — 12 combinations (4 samples × 3 intervals)
2. Tasks running in parallel (check the execution log)
3. `GATHERED:` lines — 4 groups, each with 3 VCFs
4. `FINAL:` lines — 4 merged VCF files in `results/vcfs/`

**Step 3:** Examine results:

```bash
ls results/vcfs/
cat results/vcfs/sampleA.merged.vcf
```

**Step 4: Challenge extension** — What if samples have different numbers of intervals?

Modify the workflow to scatter `sampleA` across 3 intervals but `sampleB` across only 2. The key change is that `num_intervals` must be set per-sample, not hardcoded to 3. Try solving this before looking at the hint below.

<details>
<summary>Hint</summary>

Create a map from sample ID to interval count, then look it up when adding `num_intervals`:

```nextflow
// Different intervals per sample
ch_intervals_A = channel.of('chr1', 'chr2', 'chr3')
ch_intervals_B = channel.of('chr1', 'chr2')

// Or more generally: attach intervals to each sample before combine
```

</details>

---

### Bonus: transpose in action

Transpose is the inverse of groupTuple. Paste this into a new file `bonus_transpose.nf` to see it:

```nextflow
// bonus_transpose.nf
workflow {

    // Imagine you received pre-grouped data (e.g., from a database or config)
    ch_grouped = channel.of(
        ['sampleA', ['chr1.vcf', 'chr2.vcf', 'chr3.vcf']],
        ['sampleB', ['chr1.vcf', 'chr2.vcf']]
    )

    // transpose explodes each group back into individual tuples
    ch_grouped
        .transpose()
        .view { sample, vcf -> "TRANSPOSED: ${sample} → ${vcf}" }

    // Output:
    // TRANSPOSED: sampleA → chr1.vcf
    // TRANSPOSED: sampleA → chr2.vcf
    // TRANSPOSED: sampleA → chr3.vcf
    // TRANSPOSED: sampleB → chr1.vcf
    // TRANSPOSED: sampleB → chr2.vcf
}
```

---

## Expected Outputs

After completing all three exercises your directory should look like this:

```
session10/
├── README.md
├── exercise1_split.nf
├── exercise2_join.nf
├── exercise3_scatter_gather.nf
├── bonus_transpose.nf          (optional)
├── nextflow.config
├── data/
│   ├── samplesheet.csv
│   ├── sampleA_R1.fastq
│   ├── sampleB_R1.fastq
│   ├── sampleC_R1.fastq
│   ├── sampleD_R1.fastq
│   └── extra.fastq
└── results/
    ├── pairs/
    │   ├── sampleA_combined.txt
    │   └── sampleB_combined.txt
    └── vcfs/
        ├── sampleA.merged.vcf
        ├── sampleB.merged.vcf
        ├── sampleC.merged.vcf
        └── sampleD.merged.vcf
```

---

## Debugging Tips

**1. `join` produces no output / missing samples**

The two channels must have *identical* key elements for `join` to match. If your meta maps have different fields (e.g., one has `type` and the other doesn't), they won't match. Strip them to a common key first with `.map { meta, f -> [ [id: meta.id], f ] }`.

**2. `groupTuple` hangs or the pipeline never finishes**

Without `groupKey` or `size:`, `groupTuple` waits for *all* upstream tasks to complete before emitting. If any upstream task fails or produces fewer items than expected, it waits forever. Always add `groupKey(meta, expected_count)` in the output of the scattering process.

**3. `combine` produces too many / too few combinations**

`combine` is a Cartesian product — N × M items. If `ch_intervals` is a *value channel* (from `channel.value()` or `collect()`), it pairs with every item. If it is a *queue channel*, items are consumed one-to-one. For scatter-gather you almost always want `ch_intervals` to be a value channel or use `combine` directly on two queue channels.

**4. `groupKey.target` vs the raw groupKey object**

After `groupTuple`, the key element is a `GroupKey` object, not a plain map. Calling `.view { meta, files -> meta.id }` will fail because `GroupKey` has no `.id` field. Always unwrap with `.map { key, files -> [key.target, files] }` before passing downstream.

**5. `branch` catch-all `true:` is missing**

If an item matches none of the named conditions in `branch`, it is silently dropped. Always add a `other: true` or `remainder: true` branch to capture unexpected data and log it.

---

## Key Takeaways

- Use `branch` (not `filter`) when you need multiple output streams from one channel — it evaluates each item exactly once and routes it to the first matching sub-channel.
- The scatter-gather pattern is: `combine` to fan out across a grid → parallel processing → `groupTuple` to collect results, with `groupKey` providing the expected group size so Nextflow can stream results rather than waiting for the entire pipeline.
- `join` matches on the first tuple element; keys must be identical. Strip metadata to a common key before joining, and use `remainder: true` when you need outer-join behaviour to keep unmatched samples.

---

## Connection to Other Sessions

- **Session 8 (meta map pattern):** The `[meta, reads]` tuples and `subMap` patterns here extend that session's metadata propagation.
- **Session 9 (operators deep dive):** This session applies `branch`, `join`, `groupTuple`, `combine`, and `transpose` in a realistic workflow context.
- **Session 11 (debugging):** The scatter-gather pattern is a common source of hard-to-diagnose stalls — the `groupKey` pattern introduced here is the fix.
