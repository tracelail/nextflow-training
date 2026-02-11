# Session 4 - Expected Outputs

This document describes what you should see when running each exercise.

## Basic Exercise: Modular Pipeline (main.nf)

### First Run
```bash
nextflow run main.nf
```

**Expected Console Output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `main.nf` [elegant_meitner] DSL2 - revision: a1b2c3d4

executor >  local (9)
[xx/yyyyyy] SAY_HELLO (3)         [100%] 3 of 3 ✔
[zz/aaaaaa] CONVERT_TO_UPPER (3)  [100%] 3 of 3 ✔
[bb/cccccc] COUNT_CHARACTERS (3)  [100%] 3 of 3 ✔
```

**Expected Directory Structure:**
```
results/
├── greetings/
│   ├── greeting_Alice.txt
│   ├── greeting_Bob.txt
│   └── greeting_Charlie.txt
├── upper/
│   ├── upper_greeting_Alice.txt
│   ├── upper_greeting_Bob.txt
│   └── upper_greeting_Charlie.txt
└── stats/
    ├── stats_upper_greeting_Alice.txt
    ├── stats_upper_greeting_Bob.txt
    └── stats_upper_greeting_Charlie.txt
```

**Sample File Contents:**

`results/greetings/greeting_Alice.txt`:
```
Hello, Alice! Welcome to Nextflow.
```

`results/upper/upper_greeting_Alice.txt`:
```
HELLO, ALICE! WELCOME TO NEXTFLOW.
```

`results/stats/stats_upper_greeting_Alice.txt`:
```
40 upper_greeting_Alice.txt
```

### Second Run with -resume

```bash
nextflow run main.nf -resume
```

**Expected Console Output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `main.nf` [wonderful_ptolemy] DSL2 - revision: x1y2z3

executor >  local (0)
[xx/yyyyyy] SAY_HELLO (3)         [100%] 3 of 3, cached: 3 ✔
[zz/aaaaaa] CONVERT_TO_UPPER (3)  [100%] 3 of 3, cached: 3 ✔
[bb/cccccc] COUNT_CHARACTERS (3)  [100%] 3 of 3, cached: 3 ✔

Completed at: 11-Feb-2026 10:30:45
Duration    : 2s
CPU hours   : (a few seconds saved)
Succeeded   : 9 (cached: 9)
```

**Key Observation:** Notice "cached: 3" for each process - the modular structure did not break resume functionality!

## Intermediate Exercise: Process Aliasing (exercise_02.nf)

```bash
nextflow run exercise_02.nf
```

**Expected Console Output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `exercise_02.nf` [furious_darwin] DSL2 - revision: d4e5f6

executor >  local (4)
[aa/bbbbbb] SAY_HELLO_FORMAL (2)  [100%] 2 of 2 ✔
[cc/dddddd] SAY_HELLO_CASUAL (2)  [100%] 2 of 2 ✔
```

**Expected Directory Structure:**
```
results_aliasing/
└── greetings/
    ├── greeting_Alice.txt   (from FORMAL)
    ├── greeting_Alice.txt   (from CASUAL - overwrites!)
    ├── greeting_Bob.txt     (from FORMAL)
    └── greeting_Bob.txt     (from CASUAL - overwrites!)
```

**Important Note:** Since both processes use the same publishDir and output the same filenames, the CASUAL outputs will overwrite the FORMAL ones. This demonstrates why you'd configure them differently in a real scenario (you'll learn how in Session 6).

**What you're seeing:** Two separate process instances running independently, even though they use the same underlying module code.

## Challenge Exercise: bin/ Scripts (exercise_03.nf)

```bash
nextflow run exercise_03.nf
```

**Expected Console Output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `exercise_03.nf` [nostalgic_fermat] DSL2 - revision: g7h8i9

executor >  local (6)
[ee/ffffff] SAY_HELLO (3)           [100%] 3 of 3 ✔
[gg/hhhhhh] ANALYZE_GREETING (3)   [100%] 3 of 3 ✔
```

**Expected Directory Structure:**
```
results_binscript/
├── greetings/
│   ├── greeting_Alice.txt
│   ├── greeting_Bob.txt
│   └── greeting_Charlie.txt
└── analysis/
    ├── analysis_greeting_Alice.txt
    ├── analysis_greeting_Bob.txt
    └── analysis_greeting_Charlie.txt
```

**Sample Analysis Output:**

`results_binscript/analysis/analysis_greeting_Alice.txt`:
```
=== Greeting Analysis ===
File: greeting_Alice.txt
Characters: 33
Words: 5
Lines: 1
Enthusiasm: HIGH
```

`results_binscript/analysis/analysis_greeting_Bob.txt`:
```
=== Greeting Analysis ===
File: greeting_Bob.txt
Characters: 31
Words: 5
Lines: 1
Enthusiasm: HIGH
```

**Key Observation:** The `analyze.sh` script was automatically available in the process without needing to specify `bin/` or `./bin/` - Nextflow added it to PATH automatically!

## Comparison: Monolithic vs Modular

### Run the monolithic version:
```bash
nextflow run monolithic.nf
```

### Run the modular version:
```bash
nextflow run main.nf
```

**Expected Result:** Both produce **identical outputs** in their respective results directories. The modular version is better organized but functionally equivalent.

## Work Directory Inspection

Pick any work directory from the console output, for example:

```bash
ls -la work/xx/yyyyyy*/
```

**Expected Contents:**
```
.command.begin
.command.err
.command.log
.command.out
.command.run
.command.sh
.exitcode
greeting_Alice.txt  (or whatever output was created)
```

**Check the .command.sh for the ANALYZE_GREETING process:**

```bash
# Find a work directory for ANALYZE_GREETING
cat work/gg/hhhhhh*/.command.sh
```

**Expected Content:**
```bash
#!/bin/bash
# ... (Nextflow header comments)

analyze.sh greeting_Alice.txt analysis_greeting_Alice.txt
```

**Key Observation:** No path to the script! Nextflow automatically copied `bin/analyze.sh` to this work directory and made it executable.

## Verifying Module Imports

### Check what processes are available:

```bash
nextflow inspect main.nf
```

**Expected Output:**
```
Module dependencies:
  - ./modules/local/sayHello
  - ./modules/local/convertToUpper
  - ./modules/local/countCharacters

Processes:
  - SAY_HELLO
  - CONVERT_TO_UPPER
  - COUNT_CHARACTERS
```

## Testing Resume Behavior After Modularization

This is a critical test to verify that refactoring doesn't break caching:

```bash
# Clean start
rm -rf work results .nextflow*

# Run monolithic version
nextflow run monolithic.nf

# Note the work directory hashes
nextflow log -f 'process,hash,name'

# Now run modular version with -resume
nextflow run main.nf -resume
```

**Expected Result:** The modular version should create NEW work directories (different hashes) because it's technically a different workflow. The `-resume` won't help here because we changed the workflow structure.

**However:**

```bash
# Clean start
rm -rf work results .nextflow*

# First run of modular version
nextflow run main.nf

# Second run of modular version
nextflow run main.nf -resume
```

**Expected Result:** Perfect cache hits! The modular structure maintains consistent caching as long as you don't change the imports themselves.

## Summary of What You Should See

✅ **All three exercises run successfully**
✅ **Output files are created in expected locations**  
✅ **Resume caching works correctly**  
✅ **bin/ scripts are automatically available**  
✅ **Process aliases create independent instances**  
✅ **Modular code produces identical results to monolithic code**

If you see any of these issues:
- ❌ Process not found → Check include statements
- ❌ Module file not found → Check file paths and names
- ❌ Script not found → Check bin/ location and execute permission
- ❌ Different outputs → Check that module code matches original
