# Session 4 — Modules: Organizing Code for Reuse

## Learning Objectives

After completing this session, you will be able to:
- Extract processes into separate module files for reusability
- Use the `include` statement to import processes from module files
- Organize a Nextflow project with a proper directory structure
- Use process aliasing to run the same module with different configurations
- Create helper scripts in the `bin/` directory that are automatically available to processes

## Prerequisites

- **Completed Sessions**: 1, 2, and 3
- **Required Files**: You should have a working multi-step pipeline from Session 3
- **Knowledge**: Understanding of processes, workflows, channels, and `publishDir`

## Concepts

### Why Modularize?

In Session 3, you created a multi-step pipeline with all processes defined in a single `main.nf` file. This works fine for small pipelines, but as your workflows grow, you'll want to:

1. **Reuse processes** across different pipelines
2. **Organize code** logically by function or tool
3. **Collaborate** with teams where different people work on different modules
4. **Maintain** code more easily by keeping related code together

**DSL2 modularization** is Nextflow's solution. Think of it this way:
- **Processes** are like functions in programming
- **Workflows** are like main functions that orchestrate processes
- **Modules** are like libraries that contain reusable processes

### Module File Structure

A module file is simply a `.nf` file that contains one or more process definitions:

```nextflow
// modules/local/sayHello.nf
process SAY_HELLO {
    publishDir "${params.outdir}/greetings", mode: 'copy'
    
    input:
    val name
    
    output:
    path "greeting_${name}.txt"
    
    script:
    """
    echo "Hello, ${name}!" > greeting_${name}.txt
    """
}
```

### The Include Statement

To use a module in your main workflow, you import it with `include`:

```nextflow
include { SAY_HELLO } from './modules/local/sayHello'
```

Key syntax rules (2026-compliant):
- Use lowercase `include` keyword
- Put the process name in `{ }` braces
- Use `from` followed by the module path (relative or absolute)
- Module path does **not** need `.nf` extension
- You can import multiple processes: `include { PROC1; PROC2 } from './module'`

### Process Aliasing

Sometimes you want to run the same process multiple times with different configurations. Use aliasing:

```nextflow
include { SAY_HELLO as SAY_HELLO_FORMAL } from './modules/local/sayHello'
include { SAY_HELLO as SAY_HELLO_CASUAL } from './modules/local/sayHello'
```

Now you have two independently configurable instances of the same process.

### The bin/ Directory

Nextflow automatically adds `${projectDir}/bin` to the `PATH` for all processes. This means:
- Create a `bin/` directory in your project root
- Put executable scripts there (bash, Python, R, etc.)
- They're automatically available to call from any process
- No need to specify full paths or copy scripts around

This is perfect for helper scripts, analysis tools, or any custom code your pipeline needs.

## Hands-On Exercises

### Basic: Extract Processes into Modules

You'll start with a monolithic pipeline and refactor it into a modular structure.

**Step 1: Create the project structure**

```bash
cd ~/nextflow-training/day-4
mkdir -p modules/local bin
```

**Step 2: Create `monolithic.nf` - our starting point**

This is a simple 3-process pipeline all in one file:

```nextflow
// monolithic.nf
params.outdir = 'results'
params.names = ['Alice', 'Bob', 'Charlie']

process SAY_HELLO {
    publishDir "${params.outdir}/greetings", mode: 'copy'
    
    input:
    val name
    
    output:
    path "greeting_${name}.txt"
    
    script:
    """
    echo "Hello, ${name}! Welcome to Nextflow." > greeting_${name}.txt
    """
}

process CONVERT_TO_UPPER {
    publishDir "${params.outdir}/upper", mode: 'copy'
    
    input:
    path greeting_file
    
    output:
    path "upper_${greeting_file}"
    
    script:
    """
    tr '[:lower:]' '[:upper:]' < ${greeting_file} > upper_${greeting_file}
    """
}

process COUNT_CHARACTERS {
    publishDir "${params.outdir}/stats", mode: 'copy'
    
    input:
    path greeting_file
    
    output:
    path "stats_${greeting_file}"
    
    script:
    """
    wc -m ${greeting_file} > stats_${greeting_file}
    """
}

workflow {
    // Create input channel
    names_ch = channel.of(params.names)
    
    // Chain the processes
    SAY_HELLO(names_ch)
    CONVERT_TO_UPPER(SAY_HELLO.out)
    COUNT_CHARACTERS(CONVERT_TO_UPPER.out)
}
```

**Run it to verify it works:**

```bash
nextflow run monolithic.nf
```

**Expected output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `monolithic.nf` [elegant_meitner] DSL2 - revision: a1b2c3d4

executor >  local (9)
[xx/yyyyyy] SAY_HELLO (3)       [100%] 3 of 3 ✔
[zz/aaaaaa] CONVERT_TO_UPPER (3) [100%] 3 of 3 ✔
[bb/cccccc] COUNT_CHARACTERS (3) [100%] 3 of 3 ✔
```

You should see files in `results/greetings/`, `results/upper/`, and `results/stats/`.

**Step 3: Extract SAY_HELLO into a module**

Create `modules/local/sayHello.nf`:

```nextflow
process SAY_HELLO {
    publishDir "${params.outdir}/greetings", mode: 'copy'
    
    input:
    val name
    
    output:
    path "greeting_${name}.txt"
    
    script:
    """
    echo "Hello, ${name}! Welcome to Nextflow." > greeting_${name}.txt
    """
}
```

**Step 4: Extract CONVERT_TO_UPPER into a module**

Create `modules/local/convertToUpper.nf`:

```nextflow
process CONVERT_TO_UPPER {
    publishDir "${params.outdir}/upper", mode: 'copy'
    
    input:
    path greeting_file
    
    output:
    path "upper_${greeting_file}"
    
    script:
    """
    tr '[:lower:]' '[:upper:]' < ${greeting_file} > upper_${greeting_file}
    """
}
```

**Step 5: Extract COUNT_CHARACTERS into a module**

Create `modules/local/countCharacters.nf`:

```nextflow
process COUNT_CHARACTERS {
    publishDir "${params.outdir}/stats", mode: 'copy'
    
    input:
    path greeting_file
    
    output:
    path "stats_${greeting_file}"
    
    script:
    """
    wc -m ${greeting_file} > stats_${greeting_file}
    """
}
```

**Step 6: Create the modular main workflow**

Create `main.nf`:

```nextflow
params.outdir = 'results'
params.names = ['Alice', 'Bob', 'Charlie']

// Import the processes from modules
include { SAY_HELLO } from './modules/local/sayHello'
include { CONVERT_TO_UPPER } from './modules/local/convertToUpper'
include { COUNT_CHARACTERS } from './modules/local/countCharacters'

workflow {
    // Create input channel
    names_ch = channel.of(params.names)
    
    // Chain the processes
    SAY_HELLO(names_ch)
    CONVERT_TO_UPPER(SAY_HELLO.out)
    COUNT_CHARACTERS(CONVERT_TO_UPPER.out)
}
```

**Step 7: Test that -resume still works**

```bash
# First run
nextflow run main.nf

# Second run - should use cached results
nextflow run main.nf -resume
```

**Expected output on second run:**
```
N E X T F L O W  ~  version 25.04.6
Launching `main.nf` [wonderful_ptolemy] DSL2 - revision: x1y2z3

executor >  local (0)
[xx/yyyyyy] SAY_HELLO (3)       [100%] 3 of 3, cached: 3 ✔
[zz/aaaaaa] CONVERT_TO_UPPER (3) [100%] 3 of 3, cached: 3 ✔
[bb/cccccc] COUNT_CHARACTERS (3) [100%] 3 of 3, cached: 3 ✔
```

Notice "cached: 3" - the resume cache works perfectly across the refactor!

### Intermediate: Use Process Aliasing

Now you'll create two versions of SAY_HELLO with different greeting styles.

**Step 1: Create `exercise_02.nf`**

```nextflow
params.outdir = 'results_aliasing'
params.names = ['Alice', 'Bob']

// Import the same process twice with different aliases
include { SAY_HELLO as SAY_HELLO_FORMAL } from './modules/local/sayHello'
include { SAY_HELLO as SAY_HELLO_CASUAL } from './modules/local/sayHello'

workflow {
    names_ch = channel.of(params.names)
    
    // Run both versions
    SAY_HELLO_FORMAL(names_ch)
    SAY_HELLO_CASUAL(names_ch)
}
```

**Run it:**

```bash
nextflow run exercise_02.nf
```

**Expected output:**
```
executor >  local (4)
[xx/yyyyyy] SAY_HELLO_FORMAL (2)  [100%] 2 of 2 ✔
[zz/aaaaaa] SAY_HELLO_CASUAL (2)  [100%] 2 of 2 ✔
```

You'll see that both processes run independently, even though they use the same underlying code!

**Advanced note:** In Session 6, you'll learn how to configure these aliases differently using `withName` selectors in your config file.

### Challenge: Create a bin/ Helper Script

You'll create a custom analysis script and call it from a process.

**Step 1: Create `bin/analyze.sh`**

```bash
#!/bin/bash
# analyze.sh - Custom greeting analysis tool

input_file=$1
output_file=$2

echo "=== Greeting Analysis ===" > "$output_file"
echo "File: $(basename $input_file)" >> "$output_file"
echo "Characters: $(wc -m < $input_file)" >> "$output_file"
echo "Words: $(wc -w < $input_file)" >> "$output_file"
echo "Lines: $(wc -l < $input_file)" >> "$output_file"

# Check if greeting is enthusiastic (ends with !)
if grep -q '!' "$input_file"; then
    echo "Enthusiasm: HIGH" >> "$output_file"
else
    echo "Enthusiasm: LOW" >> "$output_file"
fi
```

**Step 2: Make it executable**

```bash
chmod +x bin/analyze.sh
```

**Step 3: Create a process that uses it**

Create `modules/local/analyze.nf`:

```nextflow
process ANALYZE_GREETING {
    publishDir "${params.outdir}/analysis", mode: 'copy'
    
    input:
    path greeting_file
    
    output:
    path "analysis_${greeting_file}"
    
    script:
    """
    analyze.sh ${greeting_file} analysis_${greeting_file}
    """
}
```

**Step 4: Create `exercise_03.nf`**

```nextflow
params.outdir = 'results_binscript'
params.names = ['Alice', 'Bob', 'Charlie']

include { SAY_HELLO } from './modules/local/sayHello'
include { ANALYZE_GREETING } from './modules/local/analyze'

workflow {
    names_ch = channel.of(params.names)
    
    SAY_HELLO(names_ch)
    ANALYZE_GREETING(SAY_HELLO.out)
}
```

**Step 5: Run it**

```bash
nextflow run exercise_03.nf
```

**Step 6: Check the analysis output**

```bash
cat results_binscript/analysis/analysis_greeting_Alice.txt
```

**Expected output:**
```
=== Greeting Analysis ===
File: greeting_Alice.txt
Characters: 33
Words: 5
Lines: 1
Enthusiasm: HIGH
```

**Key insight:** Notice you didn't need to specify `bin/analyze.sh` or `./bin/analyze.sh` in the process script. Nextflow automatically made it available on the PATH!

## Debugging Tips

### Error: "Process not defined"

**Problem:**
```
ERROR ~ Error executing process > 'SAY_HELLO'
Caused by: Process `SAY_HELLO` is not defined
```

**Solution:** You forgot to include the process. Add the include statement:
```nextflow
include { SAY_HELLO } from './modules/local/sayHello'
```

### Error: "Cannot find module file"

**Problem:**
```
ERROR ~ Cannot find module file: ./modules/local/sayHelo.nf
```

**Solution:** Check your file paths:
- Is the module file named correctly? (check for typos)
- Is the path in the `include` statement correct?
- Remember: paths are relative to where you run `nextflow run`

### Error: Script in bin/ not found

**Problem:**
```
.command.sh: line 2: analyze.sh: command not found
```

**Solutions:**
- Is the script in `bin/` directory (not `bins/` or `script/`)?
- Is the script executable? Run: `chmod +x bin/analyze.sh`
- Is the script name spelled correctly in your process?

### Module changes not reflected

**Problem:** You modified a module but the changes don't appear when you re-run.

**Solution:** The resume cache might be using old results. Either:
- Use `nextflow run -resume` (tries to reuse what it can)
- Clean the cache: `nextflow clean -f` (forces re-execution)
- Check that you actually saved the module file!

### Process runs twice when using alias

**Problem:** When using aliases, the same process runs multiple times on the same data.

**Insight:** This is actually correct behavior! Each alias creates a separate process instance. If you don't want this, don't create the alias - just use the process once.

## Key Takeaways

1. **Modules enable reusability**: Extract processes into separate files so you can use them across multiple pipelines without copy-pasting code.

2. **Include syntax is simple**: `include { PROCESS } from './path/to/module'` imports processes. You can import multiple at once and use aliases for running the same process with different configurations.

3. **The bin/ directory is magical**: Any executable script in `${projectDir}/bin` is automatically on the PATH for all processes - no manual path management needed. This is the right place for helper scripts, custom tools, and analysis code.

---

**Next Steps**: In Session 5, you'll learn how to make these modules truly portable and reproducible by adding container directives, ensuring your pipeline works anywhere without dependency issues.
