# Day 2: Operators & Channel Manipulation

**Goal:** Learn how to transform, filter, and combine channels using Nextflow operators.

**Time:** 1 hour

**What you'll learn:**
- Debug channels with `view`
- Transform data with `map`, `flatten`, `flatMap`
- Aggregate with `collect` and `groupTuple`
- Combine channels with `join` and `combine`
- Route data with `filter` and `branch`
- Parse files with `splitCsv`

---

## What are Operators?

Operators are methods that transform channels. Think of them like Unix pipes:

```bash
cat file.txt | grep "error" | sort | uniq
```

In Nextflow:

```groovy
channel.of(items)
    .filter { condition }
    .map { transform }
    .view()
```

**Key concept:** Operators return NEW channels (except `view` which passes through unchanged).

---

## Exercise 1: Debugging with `view`

`view` is your print statement for channels. Use it CONSTANTLY when learning.

**Create `01_view.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Create a simple channel
    channel.of('apple', 'banana', 'cherry')
        .view()
}
```

**Run it:**
```bash
nextflow run 01_view.nf
```

**Expected output:**
```
apple
banana
cherry
```

**Now try with a closure to add labels:**

```groovy
#!/usr/bin/env nextflow

workflow {
    channel.of('apple', 'banana', 'cherry')
        .view { fruit -> "I found: ${fruit}" }
}
```

**Pro tip:** Insert `.view()` before and after ANY operator to see what changed!

---

## Exercise 2: Transform with `map`

`map` applies a function to every item. It's the MOST USED operator.

**Create `02_map.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Reverse each string
    channel.of('hello', 'world', 'nextflow')
        .map { word -> word.reverse() }
        .view()
}
```

**Run it:**
```bash
nextflow run 02_map.nf
```

**Expected output:**
```
olleh
dlrow
wolftxen
```

**Important:** Use explicit parameters (`{ word -> ... }`), NOT `$it` (deprecated).

---

## Exercise 3: Creating tuples with `map`

Real pipelines use tuples (lists) to pair metadata with files.

**First, let's create some test files:**

```bash
mkdir -p data
echo "sample1 data" > data/sample1.txt
echo "sample2 data" > data/sample2.txt
echo "sample3 data" > data/sample3.txt
```

**Create `03_map_tuples.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Create [filename, filepath] tuples
    channel.fromPath('data/*.txt')
        .map { file -> [file.baseName, file] }
        .view { tuple -> "Name: ${tuple[0]}, Path: ${tuple[1]}" }
}
```

**Run it:**
```bash
nextflow run 03_map_tuples.nf
```

**Expected output:**
```
Name: sample1, Path: /path/to/data/sample1.txt
Name: sample2, Path: /path/to/data/sample2.txt
Name: sample3, Path: /path/to/data/sample3.txt
```

**What happened?**
- `file.baseName` gets filename without extension
- `[file.baseName, file]` creates a tuple (list with 2 elements)

---

## Exercise 4: Flattening with `flatten`

`flatten` unpacks arrays into individual items.

**Create `04_flatten.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Without flatten - the whole array is ONE item
    channel.of([1, 2, 3], [4, 5, 6])
        .view { "Without flatten: ${it}" }

    // With flatten - each number is a separate item
    channel.of([1, 2, 3], [4, 5, 6])
        .flatten()
        .view { "With flatten: ${it}" }
}
```

**Run it and observe the difference:**
```bash
nextflow run 04_flatten.nf
```

**Expected output:**
```
Without flatten: [1, 2, 3]
Without flatten: [4, 5, 6]
With flatten: 1
With flatten: 2
With flatten: 3
With flatten: 4
With flatten: 5
With flatten: 6
```

---

## Exercise 5: Filtering data

`filter` keeps only items that match a condition.

**Create `05_filter.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Keep only even numbers
    channel.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        .filter { num -> num % 2 == 0 }
        .view()
}
```

**Run it:**
```bash
nextflow run 05_filter.nf
```

**Expected output:**
```
2
4
6
8
10
```

**Now try filtering tuples - let's filter samples by type:**

**Create `05b_filter_tuples.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Create sample tuples with metadata
    channel.of(
        [id: 'sample1', type: 'tumor'],
        [id: 'sample2', type: 'normal'],
        [id: 'sample3', type: 'tumor'],
        [id: 'sample4', type: 'normal']
    )
    .filter { meta -> meta.type == 'tumor' }
    .view { "Tumor sample: ${it.id}" }
}
```

---

## Exercise 6: Collecting items

`collect` gathers ALL items into a single list.

**Create `06_collect.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Collect all numbers into one list
    channel.of(1, 2, 3, 4, 5)
        .collect()
        .view { "All numbers: ${it}" }
}
```

**Run it:**
```bash
nextflow run 06_collect.nf
```

**Expected output:**
```
All numbers: [1, 2, 3, 4, 5]
```

**Key point:** 5 emissions became 1 emission containing a list of 5 items.

---

## Exercise 7: Grouping with `groupTuple`

`groupTuple` groups tuples by their first element (the key).

**Create `07_grouptuple.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Group replicates by sample ID
    channel.of(
        ['sampleA', 'replicate1.bam'],
        ['sampleB', 'replicate1.bam'],
        ['sampleA', 'replicate2.bam'],
        ['sampleA', 'replicate3.bam'],
        ['sampleB', 'replicate2.bam']
    )
    .groupTuple()
    .view { id, files -> "Sample ${id}: ${files}" }
}
```

**Run it:**
```bash
nextflow run 07_grouptuple.nf
```

**Expected output:**
```
Sample sampleA: [replicate1.bam, replicate2.bam, replicate3.bam]
Sample sampleB: [replicate1.bam, replicate2.bam]
```

**What happened?** All items with key 'sampleA' got grouped together!

---

## Exercise 8: Joining channels

`join` merges two channels on matching keys (like SQL JOIN).

**Create `08_join.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Create two channels with matching keys
    reads_ch = channel.of(
        ['sample1', 'reads.fq'],
        ['sample2', 'reads.fq'],
        ['sample3', 'reads.fq']
    )

    reference_ch = channel.of(
        ['sample1', 'ref.fa'],
        ['sample2', 'ref.fa'],
        ['sample3', 'ref.fa']
    )

    // Join them
    reads_ch
        .join(reference_ch)
        .view { id, reads, ref -> "Sample ${id}: ${reads} + ${ref}" }
}
```

**Run it:**
```bash
nextflow run 08_join.nf
```

**Expected output:**
```
Sample sample1: reads.fq + ref.fa
Sample sample2: reads.fq + ref.fa
Sample sample3: reads.fq + ref.fa
```

---

## Exercise 9: Combining channels (Cartesian product)

`combine` creates all possible pairs between two channels.

**Create `09_combine.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Samples
    samples_ch = channel.of('sampleA', 'sampleB')

    // Chromosomes
    chromosomes_ch = channel.of('chr1', 'chr2', 'chr3')

    // Combine them (scatter pattern)
    samples_ch
        .combine(chromosomes_ch)
        .view { sample, chr -> "Process ${sample} on ${chr}" }
}
```

**Run it:**
```bash
nextflow run 09_combine.nf
```

**Expected output:**
```
Process sampleA on chr1
Process sampleA on chr2
Process sampleA on chr3
Process sampleB on chr1
Process sampleB on chr2
Process sampleB on chr3
```

**Use case:** 2 samples × 3 chromosomes = 6 parallel jobs!

---

## Exercise 10: Branching (routing to multiple paths)

`branch` splits a channel into multiple outputs based on conditions.

**Create `10_branch.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Create samples with different depths
    samples = channel.of(
        [id: 'sample1', depth: 15000000],
        [id: 'sample2', depth: 35000000],
        [id: 'sample3', depth: 8000000],
        [id: 'sample4', depth: 42000000]
    )

    // Branch by sequencing depth
    samples
        .branch {
            high: it.depth >= 30000000
            medium: it.depth >= 10000000
            low: true  // catch-all
        }
        .set { result }

    result.high.view { "HIGH coverage: ${it.id} (${it.depth})" }
    result.medium.view { "MEDIUM coverage: ${it.id} (${it.depth})" }
    result.low.view { "LOW coverage: ${it.id} (${it.depth})" }
}
```

**Run it:**
```bash
nextflow run 10_branch.nf
```

**Important:** Conditions are evaluated in order. First match wins!

---

## Exercise 11: Parsing CSV files

`splitCsv` is critical for real pipelines. Let's parse a samplesheet.

**Create a sample CSV:**

```bash
cat > samplesheet.csv << 'EOF'
sample_id,fastq1,fastq2,condition
sample1,reads1_R1.fq,reads1_R2.fq,control
sample2,reads2_R1.fq,reads2_R2.fq,treated
sample3,reads3_R1.fq,reads3_R2.fq,control
EOF
```

**Create `11_splitcsv.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .view { row ->
            "Sample: ${row.sample_id}, R1: ${row.fastq1}, R2: ${row.fastq2}, Condition: ${row.condition}"
        }
}
```

**Run it:**
```bash
nextflow run 11_splitcsv.nf
```

**Now let's create proper tuples for a process:**

**Create `11b_splitcsv_tuples.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Parse CSV and create [meta, [reads]] structure
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, condition: row.condition]
            def reads = [file(row.fastq1), file(row.fastq2)]
            [meta, reads]
        }
        .view { meta, reads ->
            "Meta: ${meta}, Reads: ${reads}"
        }
}
```

**This is the standard nf-core pattern!**

---

## Exercise 12: Chaining operators (putting it all together)

Real pipelines chain multiple operators. Let's build something realistic.

**Create `12_chain_operators.nf`:**

```groovy
#!/usr/bin/env nextflow

workflow {
    // Parse samplesheet
    channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, condition: row.condition]
            def reads = [file(row.fastq1), file(row.fastq2)]
            [meta, reads]
        }
        // Only process control samples
        .filter { meta, reads -> meta.condition == 'control' }
        // Add processing flag
        .map { meta, reads ->
            [meta + [processed: true], reads]
        }
        .view { meta, reads ->
            "Will process: ${meta.id} (${meta.condition})"
        }
}
```

**Run it:**
```bash
nextflow run 12_chain_operators.nf
```

**What did we do?**
1. Parsed CSV
2. Created metadata tuples
3. Filtered for controls only
4. Added a flag to metadata
5. Viewed the result

**This is how real pipelines work!**

---

## Challenge Exercise: Build a complete operator chain

Using what you've learned, create a script that:

1. Creates a channel with sample tuples: `[id, type, file]`
2. Filters for 'tumor' samples only
3. Groups by sample ID
4. Views the result

**Hint structure:**

```groovy
#!/usr/bin/env nextflow

workflow {
    channel.of(
        ['patient1', 'tumor', 'file1.bam'],
        ['patient1', 'normal', 'file2.bam'],
        ['patient2', 'tumor', 'file3.bam'],
        ['patient1', 'tumor', 'file4.bam'],
        ['patient2', 'normal', 'file5.bam']
    )
    // YOUR CODE HERE
    // .filter ...
    // .map ...
    // .groupTuple()
    // .view()
}
```

**Expected output:**
```
[patient1, [file1.bam, file4.bam]]
[patient2, [file3.bam]]
```

---

## Key Takeaways

1. **Always use `view()`** to debug - insert it before and after operators
2. **Use explicit parameters** - `{ word -> ... }` not `$it`
3. **map** transforms, **filter** selects, **collect/groupTuple** aggregate
4. **join** matches keys, **combine** creates all pairs
5. **branch** routes to multiple paths
6. **splitCsv + map** is the standard way to read samplesheets

---

## Next Steps

- Day 3 will cover: Configuration files, parameters, and profiles
- Or continue practicing with the advanced operators: `flatMap`, `transpose`, `multiMap`

---

## Quick Reference

```groovy
// Debugging
.view()                           // Print items
.view { it -> "Label: $it" }     // Print with label

// Transform
.map { item -> transform(item) }  // Transform each item
.flatten()                        // Unpack arrays
.flatMap { x -> [x, x*2] }       // Map + flatten

// Filter
.filter { it > 10 }              // Keep matching items

// Aggregate
.collect()                        // Gather all into list
.groupTuple()                     // Group by key

// Combine
.join(other_ch)                   // Match on key
.combine(other_ch)                // Cartesian product

// Route
.branch {                         // Split to multiple channels
    condition1: test
    condition2: test
}

// Parse
.splitCsv(header: true)          // Parse CSV with headers
```
