# Getting Started - Session 7: Groovy Essentials

Welcome to Session 7! This guide will help you get started with the exercises.

## What's Included

```
session7-groovy-essentials/
├── README.md                          # Main session documentation
├── GETTING_STARTED.md                 # This file
├── SYNTAX_COMPARISON.md               # Old vs New syntax reference
├── QUICK_REFERENCE.md                 # Quick reference card
├── exercises/
│   ├── 01_collections.nf              # Basic: Lists and Maps
│   ├── 02_string_operations.nf        # Basic: String parsing
│   ├── 03_closures.nf                 # Intermediate: Explicit parameters
│   ├── 04_filename_parsing.nf         # Intermediate: Meta maps
│   └── 05_illumina_parser.nf          # Challenge: Complete this!
├── solutions/
│   └── 05_illumina_parser_solution.nf # Solution for challenge
└── data/
    └── sample_filenames.txt           # Example filenames
```

## Prerequisites

Before starting, ensure you have:
- ✅ Nextflow 25.04.6+ installed
- ✅ Completed Sessions 1-6
- ✅ Basic understanding of channels and processes

## How to Use These Materials

### Step 1: Read the README

Start by reading `README.md` to understand:
- Learning objectives
- Key Groovy concepts
- 2026 strict syntax rules
- Overview of all exercises

### Step 2: Work Through Exercises in Order

Complete the exercises sequentially. Each builds on the previous one:

#### Exercise 1: Collections (30 minutes)
```bash
cd exercises
nextflow run 01_collections.nf
```

**What you'll learn:**
- Creating and manipulating Lists
- Working with Maps (key-value pairs)
- Immutable operations with `+` operator
- Why immutability matters in parallel execution

**Success criteria:**
- Understand difference between mutable and immutable operations
- Can create and access List/Map elements
- Comfortable with the `+` operator for maps

---

#### Exercise 2: String Operations (30 minutes)
```bash
nextflow run 02_string_operations.nf
```

**What you'll learn:**
- String interpolation (GStrings)
- Tokenizing filenames
- Removing extensions
- Pattern matching

**Success criteria:**
- Can parse a filename into components
- Understand `tokenize()` vs `split()`
- Comfortable with string slicing operations

---

#### Exercise 3: Closures (45 minutes)
```bash
nextflow run 03_closures.nf
```

**What you'll learn:**
- Why implicit `it` is banned
- How to write explicit closure parameters
- Using `collect`, `findAll`, `find`, `any`
- Variable scope with `def`

**Success criteria:**
- Always use explicit parameters in closures
- Never forget `def` for local variables
- Understand side-by-side old vs new syntax examples

---

#### Exercise 4: Filename Parsing (45 minutes)
```bash
nextflow run 04_filename_parsing.nf
```

**What you'll learn:**
- Parse realistic bioinformatics filenames
- Extract sample ID, condition, read number
- Build structured meta maps
- Handle paired-end reads

**Success criteria:**
- Can write a reusable parsing function
- Understand how to group files by sample
- Can validate filename formats

---

#### Exercise 5: Illumina Parser - CHALLENGE (1-2 hours)
```bash
nextflow run 05_illumina_parser.nf
```

**Your task:** Complete the `parseIlluminaFilename()` function

**Illumina format:**
```
SampleName_S1_L001_R1_001.fastq.gz
```

**Hints:**
1. Remove `.fastq.gz` extension first
2. Use `tokenize('_')` to split
3. Pattern: `NAME_SNUM_LANE_READ_CHUNK`
4. Return a map with keys: `id`, `sample_number`, `lane`, `read`, `chunk`

**Testing:**
The file includes built-in tests. When all tests pass, you've succeeded!

**Getting stuck?**
Check `solutions/05_illumina_parser_solution.nf` for the complete solution with three different approaches.

---

### Step 3: Reference Materials

Keep these handy while working:

**QUICK_REFERENCE.md** - One-page cheat sheet
- Common collection operations
- String manipulation patterns
- Closure examples
- Most common mistakes

**SYNTAX_COMPARISON.md** - Old vs New patterns
- Complete migration guide
- Side-by-side comparisons
- Real-world examples
- Migration checklist

## Exercise Completion Checklist

Track your progress:

- [ ] Exercise 1: Collections completed
- [ ] Exercise 2: String Operations completed
- [ ] Exercise 3: Closures completed
- [ ] Exercise 4: Filename Parsing completed
- [ ] Exercise 5: Illumina Parser challenge completed
- [ ] All tests in Exercise 5 passing
- [ ] Compared my solution with provided solution
- [ ] Reviewed SYNTAX_COMPARISON.md
- [ ] Reviewed QUICK_REFERENCE.md

## Tips for Success

### 1. Run Each Exercise Multiple Times

Don't just run once - experiment!

```bash
# Run normally
nextflow run 01_collections.nf

# Modify the code, then run again
# Try different values, break things on purpose, see what happens
```

### 2. Read the Comments

Every exercise file has extensive inline comments explaining:
- Why certain patterns are used
- What each operation does
- Common pitfalls to avoid

### 3. Test Your Understanding

After each exercise, ask yourself:
- Could I write this code from scratch?
- Do I understand why it's done this way?
- Can I explain the difference between old and new syntax?

### 4. Use the REPL

Groovy has a REPL (interactive shell) - great for testing snippets:

```bash
groovysh
```

Then experiment:
```groovy
groovy:000> def samples = ['A', 'B', 'C']
groovy:000> samples.collect { s -> s.toLowerCase() }
===> [a, b, c]
```

### 5. Common Debugging Steps

If something doesn't work:

1. **Check for implicit 'it'** - Most common error
   ```groovy
   // ❌ Wrong
   list.map { it * 2 }
   
   // ✅ Right
   list.map { n -> n * 2 }
   ```

2. **Check for missing 'def'** - Causes subtle bugs
   ```groovy
   // ❌ Wrong
   list.map { n ->
       result = n * 2  // Global!
       result
   }
   
   // ✅ Right
   list.map { n ->
       def result = n * 2  // Local
       result
   }
   ```

3. **Check tokenize delimiter** - Easy to mess up
   ```groovy
   // ❌ Wrong - splits on _ AND .
   "sample_R1.fastq".tokenize('_.')
   
   // ✅ Right - remove extension first
   ("sample_R1.fastq" - '.fastq').tokenize('_')
   ```

## After Completion

Once you've finished all exercises:

1. **Review the patterns** - Make sure you're comfortable with all syntax
2. **Compare with curriculum** - Check Session 7 section in your curriculum doc
3. **Move to Session 8** - Meta map pattern in real Nextflow pipelines
4. **Keep references handy** - You'll use QUICK_REFERENCE.md constantly

## Need Help?

Common issues and solutions:

**"Syntax error: Implicit 'it' parameter is not allowed"**
→ Add explicit parameter: `{ it * 2 }` → `{ n -> n * 2 }`

**"No such variable: result"**
→ Add `def` before variable: `result = x` → `def result = x`

**"Tokenize returns unexpected results"**
→ Remove extension before tokenizing, or use single delimiter

**"Tests failing in Exercise 5"**
→ Check that you're returning a map with correct keys
→ Verify extension removal before tokenizing
→ Make sure you're using `def` for local variables

## Time Estimates

- **Exercise 1-2:** 30 minutes each (1 hour total)
- **Exercise 3:** 45 minutes
- **Exercise 4:** 45 minutes
- **Exercise 5:** 1-2 hours (includes testing and refinement)
- **Review:** 30 minutes

**Total session time:** 3.5-4.5 hours

Take breaks between exercises! This is dense material.

## What's Next?

Session 8 will apply everything you learned here to real Nextflow pipelines:
- Parse samplesheets with meta maps
- Propagate metadata through processes
- Handle missing data gracefully
- Build production-ready channel transformations

The filename parsing skills from Exercise 5 are **the foundation** for Session 8.

---

**Ready to start?** Open `README.md` and begin with Exercise 1!

Good luck! 🚀
