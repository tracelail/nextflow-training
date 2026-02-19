# Session 7 — Groovy Essentials for Nextflow Developers

## Learning Objectives

After completing this session, you will be able to:

- Work confidently with Groovy **data structures** (Lists, Maps) in Nextflow pipelines
- Write **closures with explicit parameters** following 2026 strict syntax requirements
- Parse and manipulate **filename strings** using Groovy's built-in methods
- Build **meta maps** from complex filename patterns (e.g., Illumina FASTQ naming)
- Understand which Groovy features are **banned in strict syntax** and their alternatives

## Prerequisites

**Completed sessions:** 1-6  
**Existing knowledge:** Basic Nextflow process/workflow structure, channels, configuration  
**Files needed:** None from previous sessions (this is a standalone Groovy practice session)

## Concepts

### Why Groovy Matters for Nextflow

Nextflow is built on **Groovy**, which means you're writing Groovy code whenever you manipulate data in channels, build meta maps, or transform file paths. Understanding Groovy fundamentals makes the difference between struggling with syntax errors and writing elegant, maintainable pipelines.

The three most common Groovy patterns in Nextflow are:

1. **Collections manipulation** — Lists and Maps store your sample metadata, file paths, and parameters
2. **Closures** — Anonymous functions passed to operators like `map`, `filter`, `groupTuple`
3. **String operations** — Parsing filenames, extracting sample IDs, building output paths

### Critical 2026 Syntax Rules

Nextflow's **strict syntax parser** (enabled with `NXF_SYNTAX_PARSER=v2`, default in 26.04) bans several Groovy features:

| ❌ BANNED in Strict Syntax | ✅ Use Instead |
|--------------------------------|-------------------|
| `{ it.trim() }` (implicit `it`) | `{ item -> item.trim() }` (explicit parameter) |
| `for (item in list) { }` | `list.each { item -> }` or channel operators |
| `while (condition) { }` | Functional patterns with `collect`, `findAll` |
| `switch (x) { case 1: }` | `if / else if / else` chains |
| `def x = y as Integer` | `def x = y.toInteger()` |
| Slashy strings `/.../` | Triple-quoted strings `"""..."""` |

### Variables and Scope

Always use `def` for local variables inside closures to prevent race conditions:

```groovy
// ❌ DANGEROUS - missing def causes race condition in parallel execution
samples.map { sample ->
    result = sample.name.toUpperCase()  // Shares state across parallel tasks!
    [sample.id, result]
}

// ✅ CORRECT - def creates local scope
samples.map { sample ->
    def result = sample.name.toUpperCase()  // Each task has its own variable
    [sample.id, result]
}
```

### String Interpolation

Groovy supports **GStrings** (double-quoted strings with variable interpolation):

```groovy
def name = "World"
def greeting = "Hello, ${name}!"  // Double quotes: variables interpolated
def literal = 'Hello, ${name}!'   // Single quotes: literal string
```

In Nextflow **process script blocks**, you'll often mix Groovy variables and Bash variables:

```groovy
process EXAMPLE {
    input:
    val sample_id
    
    script:
    """
    echo "Processing ${sample_id}"      // Groovy variable (interpolated by Nextflow)
    echo "User is \${USER}"             // Bash variable (escaped from Groovy)
    """
}
```

### Collections: Lists and Maps

**Lists** are ordered collections accessed by index:

```groovy
def samples = ['A', 'B', 'C']
println samples[0]        // 'A'
println samples.size()    // 3
samples << 'D'            // Add element
```

**Maps** are key-value pairs (like Python dictionaries):

```groovy
def meta = [id: 'sample1', type: 'tumor', patient: 'P001']
println meta.id           // 'sample1'
println meta['type']      // 'tumor'
meta.stage = 'III'        // Add key
meta + [batch: 'B1']      // Create new map with added key (immutable operation)
```

**Key insight:** `meta + [new_key: value]` creates a **new map** without modifying the original — this is crucial for maintaining data integrity in parallel Nextflow executions.

### Closures: The Heart of Nextflow Operators

A **closure** is an anonymous function. In 2026 strict syntax, closures **must have explicit parameters**:

```groovy
// ❌ BANNED: implicit 'it' parameter
reads_ch.map { it[1] }

// ✅ CORRECT: explicit parameter name
reads_ch.map { tuple -> tuple[1] }

// ✅ CORRECT: multiple parameters destructured
reads_ch.map { meta, reads -> [meta.id, reads] }
```

Common closure patterns:

```groovy
// Transform elements
[1, 2, 3].collect { n -> n * 2 }              // [2, 4, 6]

// Filter elements  
[1, 2, 3, 4].findAll { n -> n % 2 == 0 }      // [2, 4]

// Find first match
[1, 2, 3, 4].find { n -> n > 2 }              // 3

// Check if any match
[1, 2, 3].any { n -> n > 2 }                  // true
```

### String Methods for Filename Parsing

Real bioinformatics filenames are complex. Groovy provides powerful string methods:

```groovy
def filename = "SampleA_S1_L001_R1_001.fastq.gz"

// Tokenize: split string into list
def parts = filename.tokenize('_')            // ['SampleA', 'S1', 'L001', 'R1', '001.fastq.gz']

// Remove extension
def base = filename - '.fastq.gz'             // 'SampleA_S1_L001_R1_001'

// Take/drop characters
def prefix = filename.take(7)                 // 'SampleA'
def suffix = filename[-9..-1]                 // 'fastq.gz'

// Find pattern
def hasR1 = filename.contains('_R1_')         // true
def readNum = filename =~ /_R(\d)_/           // Regex matcher
if (readNum) {
    println readNum[0][1]                     // '1'
}

// Replace patterns
def cleaned = filename.replaceAll(/_S\d+_/, '_')  // 'SampleA_L001_R1_001.fastq.gz'
```

### The Meta Map Pattern

In real pipelines, you'll parse filenames into **meta maps** that carry metadata through your workflow:

```groovy
// Input: SampleA_S1_L001_R1_001.fastq.gz
// Output: [id: 'SampleA', lane: 'L001', read: 'R1']

def filename = "SampleA_S1_L001_R1_001.fastq.gz"
def parts = filename.tokenize('_')

def meta = [
    id: parts[0],           // 'SampleA'
    lane: parts[2],         // 'L001'
    read: parts[3]          // 'R1'
]
```

## Hands-On Exercises

This session has **5 separate exercise files**, progressing from basic to advanced:

1. **`01_collections.nf`** — Working with Lists and Maps
2. **`02_string_operations.nf`** — Parsing and manipulating strings
3. **`03_closures.nf`** — Writing explicit-parameter closures
4. **`04_filename_parsing.nf`** — Building meta maps from filenames
5. **`05_illumina_parser.nf`** — **CHALLENGE**: Complete Illumina filename parser

Each file is a standalone Nextflow script you can run with `nextflow run <file>.nf`.

---

### Exercise 1: Collections (Basic)

**File:** `exercises/01_collections.nf`

This exercise teaches you to create and manipulate Lists and Maps — the fundamental data structures in Nextflow.

**Run it:**
```bash
nextflow run exercises/01_collections.nf
```

**What you'll practice:**
- Creating Lists and Maps
- Accessing elements by index and key
- Adding elements with `<<` and `+`
- Immutable map operations

**Expected output:**
```
Sample list: [A, B, C, D]
First sample: A
Meta map: [id:sample1, type:tumor, patient:P001, stage:III]
Sample type: tumor
Extended meta: [id:sample1, type:tumor, patient:P001, stage:III, batch:B1]
Original meta unchanged: [id:sample1, type:tumor, patient:P001, stage:III]
```

**Key insight:** Notice that `meta + [batch: 'B1']` creates a **new map** without modifying `meta`. This is critical for parallel execution safety.

---

### Exercise 2: String Operations (Basic)

**File:** `exercises/02_string_operations.nf`

Learn how to parse and manipulate filename strings — a daily task in bioinformatics pipelines.

**Run it:**
```bash
nextflow run exercises/02_string_operations.nf
```

**What you'll practice:**
- String interpolation (GStrings)
- Tokenizing strings with `tokenize()`
- Removing extensions with `-` operator
- Extracting substrings with `take()` and subscript ranges
- Pattern matching with `contains()` and regex

**Expected output:**
```
Filename: sample1_tumor_R1.fastq.gz
Without extension: sample1_tumor_R1
Tokenized: [sample1, tumor, R1.fastq.gz]
First component: sample1
Contains R1: true
Greeting: Hello, sample1!
```

---

### Exercise 3: Closures (Intermediate)

**File:** `exercises/03_closures.nf`

Master closure syntax with explicit parameters — the foundation of all Nextflow operators.

**Run it:**
```bash
nextflow run exercises/03_closures.nf
```

**What you'll practice:**
- Writing closures with explicit parameters
- Using `collect` (map in functional programming)
- Using `findAll` (filter)
- Using `find` (first match)
- **Comparing old vs new syntax** side-by-side

**Expected output:**
```
=== Old (Implicit 'it') vs New (Explicit Parameter) Syntax ===

Doubled numbers: [2, 4, 6, 8, 10]
Even numbers: [2, 4]
First large number: 6
Any negatives? false

=== Closure with Multiple Parameters ===
Samples with metadata:
  - sample1: tumor
  - sample2: normal
  - sample3: tumor
```

**Key insight:** Every closure in this exercise shows **both syntaxes** with comments explaining why strict syntax requires explicit parameters.

---

### Exercise 4: Filename Parsing (Intermediate)

**File:** `exercises/04_filename_parsing.nf`

Build meta maps from realistic bioinformatics filenames.

**Run it:**
```bash
nextflow run exercises/04_filename_parsing.nf
```

**What you'll practice:**
- Parsing underscore-delimited filenames
- Extracting sample ID, condition, and read number
- Building structured meta maps
- Handling paired-end reads (R1/R2)

**Expected output:**
```
Parsing: sample1_tumor_R1.fastq.gz
  Meta: [id:sample1, condition:tumor, read:R1]

Parsing: sample2_normal_R2.fastq.gz
  Meta: [id:sample2, condition:normal, read:R2]

Parsing: sample3_tumor_R1.fastq.gz
  Meta: [id:sample3, condition:tumor, read:R1]
```

---

### Exercise 5: Illumina Parser (Challenge)

**File:** `exercises/05_illumina_parser.nf`

**This is the CHALLENGE exercise** — you'll write a complete function to parse complex Illumina FASTQ filenames into structured meta maps.

**Illumina filename format:**
```
SampleName_S1_L001_R1_001.fastq.gz
├─────────┬──┬────┬──┬───┬────────
│         │  │    │  │   └─ Chunk (001)
│         │  │    │  └───── Read (R1/R2)
│         │  │    └──────── Lane (L001-L008)
│         │  └───────────── Sample number (S1-S999)
│         └──────────────── Sample name
└────────────────────────── Base identifier
```

**Your task:** Complete the `parseIlluminaFilename()` function to extract all components.

**Run it:**
```bash
nextflow run exercises/05_illumina_parser.nf
```

**Expected output:**
```
Parsing: PatientA_S1_L001_R1_001.fastq.gz
  Meta: [id:PatientA, sample_number:S1, lane:L001, read:R1, chunk:001]

Parsing: TumorB_S12_L002_R2_001.fastq.gz
  Meta: [id:TumorB, sample_number:S12, lane:L002, read:R2, chunk:001]

Parsing: Control_S5_L001_R1_001.fastq.gz
  Meta: [id:Control, sample_number:S5, lane:L001, read:R1, chunk:001]
```

**Hints:**
1. Use `tokenize('_')` to split the filename
2. Remove `.fastq.gz` extension first
3. The pattern is always: `NAME_SNUM_LANE_READ_CHUNK`
4. Use `def` for all local variables
5. Return a Map with keys: `id`, `sample_number`, `lane`, `read`, `chunk`

**Solution available in:** `solutions/05_illumina_parser_solution.nf`

---

## Debugging Tips

### Common Error 1: Missing `def` in Closure

```groovy
// ❌ WRONG - race condition in parallel execution
samples.map { s ->
    result = s.toUpperCase()  // Global variable!
    result
}
```

**Error:** Unpredictable results when running in parallel  
**Fix:** Add `def` before variable declaration

```groovy
// ✅ CORRECT
samples.map { s ->
    def result = s.toUpperCase()  // Local variable
    result
}
```

### Common Error 2: Using Implicit `it` in Strict Syntax

```groovy
// ❌ WRONG - implicit 'it' banned in strict syntax
channel.of(1, 2, 3).map { it * 2 }
```

**Error:** `Syntax error: Implicit 'it' parameter is not allowed`  
**Fix:** Use explicit parameter name

```groovy
// ✅ CORRECT
channel.of(1, 2, 3).map { n -> n * 2 }
```

### Common Error 3: Modifying Maps Incorrectly

```groovy
// ❌ WRONG - attempting to modify map directly
def meta = [id: 'A']
meta.type = 'tumor'           // This works but creates mutable state
meta.patient = 'P001'         // Dangerous in parallel workflows
```

**Problem:** Mutable state can cause race conditions  
**Fix:** Create new maps with `+` operator

```groovy
// ✅ CORRECT - immutable operation
def meta = [id: 'A']
def extended_meta = meta + [type: 'tumor', patient: 'P001']
// Original 'meta' is unchanged, 'extended_meta' is a new map
```

### Common Error 4: String Interpolation vs Bash Variables

```groovy
process EXAMPLE {
    input:
    val sample_id
    
    script:
    """
    echo "Sample: ${sample_id}"    // Groovy interpolation - CORRECT
    echo "User: ${USER}"            // Tries to interpolate Groovy var 'USER' - WRONG!
    """
}
```

**Error:** `No such variable: USER`  
**Fix:** Escape the `$` for Bash variables

```groovy
process EXAMPLE {
    input:
    val sample_id
    
    script:
    """
    echo "Sample: ${sample_id}"     // Groovy variable
    echo "User: \${USER}"           // Bash variable (escaped)
    """
}
```

### Common Error 5: Incorrect Tokenize Usage

```groovy
def filename = "sample_R1.fastq.gz"
def parts = filename.tokenize('_.')   // ❌ Tokenizes on _ AND .
println parts  // [sample, R1, fastq, gz] - not what we wanted!
```

**Fix:** Tokenize only on the primary delimiter, then handle extensions separately

```groovy
def filename = "sample_R1.fastq.gz"
def clean = filename - '.fastq.gz'     // Remove extension first
def parts = clean.tokenize('_')        // Now tokenize on underscore
println parts  // [sample, R1] - correct!
```

---

## Key Takeaways

1. **Strict syntax requires explicit closure parameters** — `{ item -> item.field }` not `{ it.field }`. This makes code more readable and prevents subtle bugs in parallel execution.

2. **Use `def` for all local variables inside closures** — Without `def`, variables leak into global scope and create race conditions when Nextflow executes processes in parallel.

3. **Create new maps with `+` instead of modifying existing ones** — `meta + [key: value]` returns a new map, keeping the original unchanged. This is essential for safe parallel pipeline execution.

4. **String manipulation is a core Nextflow skill** — Parsing filenames with `tokenize()`, removing extensions with `-`, and extracting substrings with slicing operations are daily tasks in bioinformatics pipelines.

5. **The meta map pattern connects all pipeline stages** — Learning to extract metadata from filenames into structured maps (`[id: 'sample1', type: 'tumor']`) enables sophisticated sample tracking through complex multi-step workflows.

---

## What's Next?

**Session 8** builds on these Groovy fundamentals by teaching the **meta map pattern** in real Nextflow pipelines — you'll parse samplesheets, propagate metadata through processes, and handle missing data gracefully. The filename parsing skills from Exercise 5 will become the foundation for building production-ready pipelines.

**Before Session 8:** Make sure you're comfortable with Exercise 5 (Illumina parser). The ability to transform filename strings into structured meta maps is the single most valuable Groovy skill for Nextflow developers.
