# Groovy Syntax Comparison: Old vs New (2026 Strict)

This document provides a comprehensive side-by-side comparison of deprecated patterns and their 2026-compliant replacements.

## Quick Reference Table

| Pattern | ❌ Old (Banned) | ✅ New (2026 Strict) |
|---------|----------------|---------------------|
| **Implicit it** | `{ it * 2 }` | `{ n -> n * 2 }` |
| **Channel factory** | `Channel.of()` | `channel.of()` |
| **For loop** | `for (x in list) { }` | `list.each { x -> }` |
| **While loop** | `while (x < 10) { }` | Use recursion or collect |
| **Switch statement** | `switch(x) { case 1: }` | `if/else if/else` |
| **Type casting** | `x as Integer` | `x.toInteger()` |
| **Slashy strings** | `/path/to/file/` | `"""path/to/file"""` |

---

## 1. Closures - Implicit vs Explicit Parameters

### The Problem with Implicit 'it'

```groovy
// ❌ OLD: Implicit 'it' parameter
numbers.collect { it * 2 }
files.map { it.baseName }
samples.filter { it.type == 'tumor' }

// Problems:
// - Not clear what 'it' represents
// - Harder to read in nested closures
// - Banned in strict syntax mode
```

### 2026 Solution: Explicit Parameters

```groovy
// ✅ NEW: Explicit parameter names
numbers.collect { n -> n * 2 }
files.map { file -> file.baseName }
samples.filter { sample -> sample.type == 'tumor' }

// Benefits:
// - Clear, self-documenting code
// - No confusion in nested closures
// - Required in strict syntax
```

### Real-World Examples

```groovy
// ❌ OLD: Hard to read
reads_ch
    .map { it[1] }
    .flatten()
    .map { [it.baseName, it] }

// ✅ NEW: Clear and explicit
reads_ch
    .map { tuple -> tuple[1] }
    .flatten()
    .map { file -> [file.baseName, file] }
```

---

## 2. Channel Factories - Uppercase vs Lowercase

### The Change

```groovy
// ❌ OLD: Uppercase Channel (deprecated since 20.07)
Channel.of('A', 'B', 'C')
Channel.fromPath('*.fastq')
Channel.fromList([1, 2, 3])
Channel.value('constant')

// ✅ NEW: Lowercase channel (current standard)
channel.of('A', 'B', 'C')
channel.fromPath('*.fastq')
channel.fromList([1, 2, 3])
channel.value('constant')
```

### Why It Matters

The lowercase form is now **enforced** by nf-core tools 3.5.0+ and will be required in all nf-core pipelines by Q2 2026.

---

## 3. Loops - Imperative vs Functional

### For Loops → Functional Patterns

```groovy
// ❌ OLD: For loop (banned in strict syntax)
def results = []
for (sample in samples) {
    results << process(sample)
}

// ✅ NEW: Use collect
def results = samples.collect { sample -> process(sample) }
```

### While Loops → Recursive/Collect Patterns

```groovy
// ❌ OLD: While loop (banned in strict syntax)
def i = 0
def sum = 0
while (i < numbers.size()) {
    sum += numbers[i]
    i++
}

// ✅ NEW: Use built-in methods
def sum = numbers.sum()

// Or for custom logic, use recursion or inject
def result = numbers.inject(0) { acc, n -> acc + n }
```

### Common Loop Replacements

```groovy
// ❌ OLD: Iterating and filtering
def tumors = []
for (sample in samples) {
    if (sample.type == 'tumor') {
        tumors << sample
    }
}

// ✅ NEW: Use findAll
def tumors = samples.findAll { sample -> sample.type == 'tumor' }


// ❌ OLD: Transforming elements
def ids = []
for (meta in metas) {
    ids << meta.id
}

// ✅ NEW: Use collect
def ids = metas.collect { meta -> meta.id }


// ❌ OLD: Finding first match
def found = null
for (item in list) {
    if (item > 10) {
        found = item
        break
    }
}

// ✅ NEW: Use find
def found = list.find { item -> item > 10 }
```

---

## 4. Switch Statements → If/Else Chains

```groovy
// ❌ OLD: Switch statement (banned in strict syntax)
def result
switch (sample_type) {
    case 'tumor':
        result = processTumor()
        break
    case 'normal':
        result = processNormal()
        break
    default:
        result = processUnknown()
}

// ✅ NEW: If/else chain
def result
if (sample_type == 'tumor') {
    result = processTumor()
} else if (sample_type == 'normal') {
    result = processNormal()
} else {
    result = processUnknown()
}

// ✅ BETTER: Ternary operator for simple cases
def result = (sample_type == 'tumor') ? processTumor() : processNormal()

// ✅ BEST: Map lookup for multiple options
def processors = [
    tumor: { -> processTumor() },
    normal: { -> processNormal() }
]
def result = processors[sample_type]?.call() ?: processUnknown()
```

---

## 5. Type Casting

```groovy
// ❌ OLD: 'as' soft casting (banned in strict syntax)
def num = str as Integer
def list = value as List
def bool = value as Boolean

// ✅ NEW: Explicit conversion methods
def num = str.toInteger()
def list = value.toList()
def bool = value.toBoolean()
```

---

## 6. String Patterns

### Slashy Strings

```groovy
// ❌ OLD: Slashy strings (deprecated in strict syntax)
def path = /some/path/to/file/
def regex = /\d+\.\d+/

// ✅ NEW: Triple-quoted strings or escaped strings
def path = """some/path/to/file"""
def regex = '\\d+\\.\\d+'
```

### String Interpolation in Process Scripts

```groovy
process EXAMPLE {
    input:
    val sample_id
    
    script:
    """
    # ✅ CORRECT: Groovy variable
    echo "Processing ${sample_id}"
    
    # ✅ CORRECT: Bash variable (escaped from Groovy)
    echo "User is \${USER}"
    echo "Home is \${HOME}"
    
    # ❌ WRONG: This tries to interpolate a Groovy variable 'USER'
    # echo "User is ${USER}"
    """
}
```

---

## 7. Variable Scope - Always Use 'def'

```groovy
// ❌ DANGEROUS: Missing 'def' causes race conditions
samples.map { sample ->
    result = sample.toUpperCase()  // Global variable!
    result
}

// ✅ SAFE: Use 'def' for local scope
samples.map { sample ->
    def result = sample.toUpperCase()  // Local variable
    result
}

// Why this matters:
// Without 'def', variables leak to global scope
// In parallel Nextflow execution, this causes race conditions
// Multiple processes can overwrite the same global variable
```

---

## 8. Map Operations - Mutable vs Immutable

```groovy
// ⚠️ MUTABLE: Direct modification (risky in parallel execution)
def meta = [id: 'A']
meta.type = 'tumor'           // Modifies original map
meta.patient = 'P001'         // Dangerous in parallel workflows

// ✅ IMMUTABLE: Create new maps with '+'
def meta = [id: 'A']
def extended = meta + [type: 'tumor', patient: 'P001']
// Original 'meta' is unchanged
// 'extended' is a new map
// Safe for parallel execution
```

---

## 9. Process Input/Output Qualifiers

```groovy
process OLD_STYLE {
    input:
    set val(meta), file(reads) from reads_ch  // ❌ OLD
    file reference from ref_ch                 // ❌ OLD
    
    output:
    set val(meta), file("*.bam") into bam_ch  // ❌ OLD
    file "versions.yml" into versions_ch       // ❌ OLD
}

process NEW_STYLE {
    input:
    tuple val(meta), path(reads)              // ✅ NEW
    path reference                             // ✅ NEW
    
    output:
    tuple val(meta), path("*.bam")            // ✅ NEW
    path "versions.yml"                        // ✅ NEW
}
```

---

## 10. Import Statements

```groovy
// ❌ OLD: Import statements (banned in strict syntax)
import java.nio.file.Files
import groovy.json.JsonSlurper

// ✅ NEW: Use fully qualified names
def files = java.nio.file.Files.list(path)
def json = new groovy.json.JsonSlurper().parse(file)
```

---

## Complete Before/After Example

Here's a complete example showing multiple pattern updates:

### Before (Old Syntax)

```groovy
#!/usr/bin/env nextflow

Channel
    .fromPath('*.fastq.gz')
    .map { [it.baseName, it] }
    .set { reads_ch }

process PROCESS_READS {
    input:
    set val(name), file(reads) from reads_ch
    
    output:
    set val(name), file("*.bam") into bam_ch
    
    script:
    """
    process_reads.sh ${reads}
    """
}

bam_ch.map { it[0] }.view()
```

### After (2026 Strict Syntax)

```groovy
#!/usr/bin/env nextflow

workflow {
    reads_ch = channel
        .fromPath('*.fastq.gz')
        .map { file -> [file.baseName, file] }
    
    PROCESS_READS(reads_ch)
    
    PROCESS_READS.out.bam
        .map { tuple -> tuple[0] }
        .view()
}

process PROCESS_READS {
    input:
    tuple val(name), path(reads)
    
    output:
    tuple val(name), path("*.bam"), emit: bam
    
    script:
    """
    process_reads.sh ${reads}
    """
}
```

---

## Migration Checklist

Use this checklist when updating old Nextflow code:

- [ ] Replace all `Channel.` with `channel.`
- [ ] Add explicit parameter names to all closures (remove `it`)
- [ ] Replace `for` loops with `each`, `collect`, or `findAll`
- [ ] Replace `while` loops with functional patterns
- [ ] Replace `switch` with `if/else` or map lookups
- [ ] Replace `as Type` with `.toType()`
- [ ] Replace slashy strings with triple-quoted strings
- [ ] Add `def` to all local variables in closures
- [ ] Replace `set`/`file` qualifiers with `tuple`/`path`
- [ ] Remove all `from`/`into` channel connections (use workflow block)
- [ ] Use `emit:` for named outputs
- [ ] Remove `import` statements, use fully qualified names

---

## Testing Your Code

To verify your code is strict-syntax compliant:

```bash
# Enable strict syntax parser
export NXF_SYNTAX_PARSER=v2

# Run nextflow lint (available in 25.04+)
nextflow lint your_script.nf

# Run your pipeline
nextflow run your_script.nf
```

If you see errors about "implicit 'it' parameter" or "switch statement not allowed", you have deprecated syntax that needs updating.
