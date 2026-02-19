# Groovy Quick Reference Card - 2026 Edition

Essential Groovy patterns for Nextflow developers

---

## Collections

### Lists
```groovy
def samples = ['A', 'B', 'C']      // Create list
samples[0]                         // Access by index: 'A'
samples[-1]                        // Last element: 'C'
samples.size()                     // Length: 3
samples << 'D'                     // Append: ['A', 'B', 'C', 'D']
samples + ['E', 'F']               // Concatenate (immutable)
samples[1..2]                      // Slice: ['B', 'C']
```

### Maps
```groovy
def meta = [id: 'A', type: 'tumor']    // Create map
meta.id                                 // Access: 'A'
meta['type']                            // Alternative: 'tumor'
meta.stage = 'III'                      // Add key (mutable)
meta + [patient: 'P001']                // Merge maps (immutable)
meta.containsKey('id')                  // Check key: true
meta.keySet()                           // All keys: ['id', 'type', 'stage']
```

---

## Strings

### Basic Operations
```groovy
def name = "sample1"
"Hello ${name}"                    // Interpolation: "Hello sample1"
'Literal ${name}'                  // No interpolation: 'Literal ${name}'
name.toUpperCase()                 // "SAMPLE1"
name.toLowerCase()                 // "sample1"
name.size()                        // 7
name.take(6)                       // "sample"
name.drop(6)                       // "1"
name[0..5]                         // "sample" (range)
```

### Parsing Filenames
```groovy
def file = "sample1_R1.fastq.gz"
file - '.fastq.gz'                 // Remove: "sample1_R1"
file.tokenize('_')                 // Split: ['sample1', 'R1.fastq.gz']
file.split('_')                    // Split (preserves empty): ['sample1', 'R1.fastq.gz']
file.contains('R1')                // Check: true
file.startsWith('sample')          // true
file.endsWith('.gz')               // true
file.replace('_', '-')             // "sample1-R1.fastq.gz"
file.replaceAll('_R\d', '')        // "sample1.fastq.gz"
```

### Regex Matching
```groovy
def text = "sample_R1_001"
def matcher = text =~ /_R(\d)_/
if (matcher) {
    println matcher[0][0]          // Full match: "_R1_"
    println matcher[0][1]          // Group 1: "1"
}
```

---

## Closures (Explicit Parameters Required!)

### Transform: collect
```groovy
// ✅ CORRECT - explicit parameter
[1, 2, 3].collect { n -> n * 2 }               // [2, 4, 6]
files.collect { file -> file.baseName }         // Extract basenames
metas.collect { meta -> meta.id }               // Extract IDs

// ❌ WRONG - implicit 'it' (banned in strict syntax)
// [1, 2, 3].collect { it * 2 }
```

### Filter: findAll
```groovy
// ✅ CORRECT
[1, 2, 3, 4].findAll { n -> n % 2 == 0 }       // [2, 4]
samples.findAll { s -> s.type == 'tumor' }      // Filter tumors

// ❌ WRONG
// [1, 2, 3, 4].findAll { it % 2 == 0 }
```

### Find First: find
```groovy
// ✅ CORRECT
[1, 2, 3, 4].find { n -> n > 2 }               // 3
samples.find { s -> s.id == 'A' }               // First match

// ❌ WRONG
// [1, 2, 3, 4].find { it > 2 }
```

### Check Conditions
```groovy
// ✅ CORRECT
[1, 2, 3].any { n -> n > 2 }                   // true (at least one)
[1, 2, 3].every { n -> n > 0 }                 // true (all)
[1, 2, 3].none { n -> n < 0 }                  // true (none)

// ❌ WRONG
// [1, 2, 3].any { it > 2 }
```

### Iterate: each
```groovy
// ✅ CORRECT
samples.each { sample ->
    println sample.id
}

// ❌ WRONG
// samples.each { println it.id }
```

---

## Common Patterns

### Build Meta Map from Filename
```groovy
def filename = "sample1_tumor_R1.fastq.gz"
def base = filename - '.fastq.gz'
def parts = base.tokenize('_')
def meta = [
    id: parts[0],           // 'sample1'
    condition: parts[1],    // 'tumor'
    read: parts[2]          // 'R1'
]
```

### Parse Illumina Filename
```groovy
def filename = "SampleA_S1_L001_R1_001.fastq.gz"
def parts = (filename - '.fastq.gz').tokenize('_')
def meta = [
    id: parts[0],              // 'SampleA'
    sample_number: parts[1],   // 'S1'
    lane: parts[2],            // 'L001'
    read: parts[3],            // 'R1'
    chunk: parts[4]            // '001'
]
```

### Group Files by Sample
```groovy
def files = [
    'sampleA_R1.fastq',
    'sampleA_R2.fastq',
    'sampleB_R1.fastq'
]

def by_sample = files.groupBy { file ->
    file.tokenize('_')[0]  // Group by sample name
}
// Result: [sampleA: ['sampleA_R1.fastq', 'sampleA_R2.fastq'], 
//          sampleB: ['sampleB_R1.fastq']]
```

### Filter and Transform
```groovy
def samples = [
    [id: 'A', reads: 1000000],
    [id: 'B', reads: 500000],
    [id: 'C', reads: 2000000]
]

// Get IDs of high-coverage samples
def high_cov = samples
    .findAll { s -> s.reads > 750000 }
    .collect { s -> s.id }
// Result: ['A', 'C']
```

---

## Variable Scope

### Always Use 'def' in Closures!
```groovy
// ❌ DANGEROUS - race condition in parallel execution
samples.map { s ->
    result = s.toUpperCase()  // Global variable!
    result
}

// ✅ SAFE - local scope
samples.map { s ->
    def result = s.toUpperCase()  // Local variable
    result
}
```

---

## Map Operations

### Immutable Updates (Safe for Parallel)
```groovy
def meta = [id: 'A', type: 'tumor']

// ⚠️ MUTABLE (risky in parallel)
meta.patient = 'P001'

// ✅ IMMUTABLE (safe)
def extended = meta + [patient: 'P001']
// Original 'meta' unchanged
// 'extended' is new map
```

---

## Elvis Operator (Default Values)

```groovy
def meta = [id: 'A']

// Without Elvis - returns null if key missing
def type = meta.type                    // null

// With Elvis - provides default
def type = meta.type ?: 'unknown'       // 'unknown'

// Useful in meta map operations
def condition = meta.condition ?: 'control'
```

---

## Ternary Operator

```groovy
// Compact if/else
def result = (condition) ? value_if_true : value_if_false

// Examples
def label = (type == 'tumor') ? 'T' : 'N'
def suffix = (paired) ? '_paired' : '_single'
```

---

## Safe Navigation Operator

```groovy
def meta = [id: 'A']

// Without safe navigation - throws error if null
// def len = meta.patient.size()  // ERROR

// With safe navigation - returns null if any step is null
def len = meta.patient?.size()   // null (no error)

// Useful with method chains
def result = meta.nested?.field?.value ?: 'default'
```

---

## Common Nextflow-Specific Patterns

### Extract Basename
```groovy
// ✅ CORRECT
files.map { file -> file.baseName }

// Or for strings
files.map { filename -> 
    filename.split('/')[-1] - '.fastq.gz'
}
```

### Build Tuple with Meta
```groovy
// ✅ CORRECT
files.map { file ->
    def meta = [id: file.baseName]
    [meta, file]
}
```

### Add Field to Meta
```groovy
// ✅ CORRECT (immutable)
reads_ch.map { meta, reads ->
    def extended_meta = meta + [read_count: reads.size()]
    [extended_meta, reads]
}
```

---

## Debugging Tips

### Print Variable Type
```groovy
println meta.getClass()  // class java.util.LinkedHashMap
```

### Print All Map Keys/Values
```groovy
meta.each { key, value ->
    println "${key}: ${value}"
}
```

### Check if Empty
```groovy
list.isEmpty()           // true if list is empty
map.isEmpty()            // true if map is empty
string.isEmpty()         // true if string is empty
```

---

## Most Common Mistakes

1. **Forgetting 'def'** → Race conditions
2. **Using implicit 'it'** → Banned in strict syntax
3. **Tokenizing with multiple delimiters** → Splits on ALL chars
4. **Modifying maps directly** → Unsafe in parallel
5. **Forgetting extension removal before parsing** → Wrong split

---

## Quick Test Yourself

Can you spot the errors?

```groovy
// 1. What's wrong here?
samples.map { it.toUpperCase() }

// 2. What's wrong here?
def file = "sample_R1.fastq.gz"
def parts = file.tokenize('_.')

// 3. What's wrong here?
samples.map { s ->
    result = process(s)
    result
}
```

**Answers:**
1. Implicit 'it' - should be `{ s -> s.toUpperCase() }`
2. Tokenizes on `_` AND `.` - should remove extension first
3. Missing 'def' - should be `def result = process(s)`
