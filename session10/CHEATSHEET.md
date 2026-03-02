# Session 10 — Operator Quick Reference

## Splitting operators

| Operator  | Use when…                                      | Output               |
|-----------|------------------------------------------------|----------------------|
| `filter`  | You need ONE boolean subset                    | Single channel       |
| `branch`  | You need TWO or MORE named output streams      | Named sub-channels   |

### filter — keep items matching a condition
```nextflow
ch_tumor = ch_samples.filter { meta -> meta.type == 'tumor' }
```

### branch — route to named sub-channels (single pass)
```nextflow
ch_samples
    .branch { meta ->
        tumor:  meta.type == 'tumor'
        normal: meta.type == 'normal'
        other:  true           // ALWAYS include a catch-all
    }
    .set { ch_branched }

// Access named outputs:
ch_branched.tumor
ch_branched.normal
```

---

## Joining operators

### join — inner join by key (default)
```nextflow
// Both channels must have IDENTICAL first elements to match
ch_a.join(ch_b)

// Outer join — keeps unmatched items (missing side = null)
ch_a.join(ch_b, remainder: true)

// Join on specific index
ch_a.join(ch_b, by: [0, 1])
```

**Common pitfall:** Strip metadata to a common key before joining:
```nextflow
ch_tumor_keyed = PROCESS_TUMOR.out
    .map { meta, file -> [ [id: meta.id], file ] }
```

---

## Aggregation operators

### groupTuple — collect items sharing the same key
```nextflow
// Basic (waits for ALL items — can stall!)
ch.groupTuple()

// With size — emits as soon as group is complete (preferred)
ch.groupTuple(size: 3)

// With groupKey — variable group sizes (best practice)
// Set in process output:
tuple val(groupKey(meta, meta.num_intervals)), path(vcf)

// Then groupTuple emits per-sample as soon as num_intervals arrive
ch.groupTuple()

// Unwrap groupKey AFTER groupTuple:
.map { key, files -> [key.target, files] }
```

---

## Scatter operator

### combine — Cartesian product (N × M)
```nextflow
// All combinations of samples and intervals
ch_bams.combine(ch_intervals)
// [meta, bam] × [interval] → [meta, bam, interval]

// With matching key (like combine + inner join)
ch_a.combine(ch_b, by: 0)
```

---

## Inverse of groupTuple

### transpose — flatten lists back into individual tuples
```nextflow
// [key, [a, b, c]] → [key, a], [key, b], [key, c]
ch.transpose()

// Keep incomplete rows (fill with null)
ch.transpose(remainder: true)
```

---

## The complete scatter-gather pattern

```nextflow
// 1. Align (one task per sample)
ALIGN(ch_samples)

// 2. SCATTER — combine with intervals
ch_scattered = ALIGN.out.combine(ch_intervals)

// 3. Process each combination in parallel
GENOTYPE_INTERVAL(ch_scattered)
//   └─ process output uses: tuple val(groupKey(meta, meta.num_intervals)), path(vcf)

// 4. GATHER — groupTuple collects all intervals per sample
ch_gathered = GENOTYPE_INTERVAL.out
    .groupTuple()
    .map { key, vcfs -> [key.target, vcfs] }   // unwrap groupKey!

// 5. Merge
MERGE_VCFS(ch_gathered)
```

---

## 2026 Syntax Rules (always apply)

| ❌ Old / deprecated          | ✅ 2026 correct                    |
|-----------------------------|-------------------------------------|
| `Channel.of()`              | `channel.of()`                     |
| `{ it.type == 'tumor' }`    | `{ meta -> meta.type == 'tumor' }` |
| `file` qualifier            | `path` qualifier                   |
| `set` qualifier             | `tuple val(...) / path(...)`       |
| `shell:` block              | `script:` block                    |
