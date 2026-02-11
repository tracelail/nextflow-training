# Session 4 - Testing Guide

Follow these steps in order to work through all the exercises.

## Pre-flight Check

```bash
# Make sure you're in the session 4 directory
cd ~/nextflow-training/day-4
```

## Part 1: Understanding the Monolithic Approach

**Objective:** See how a multi-process pipeline looks when everything is in one file.

### Step 1: Examine the monolithic pipeline

```bash
cat monolithic.nf
```

**What to notice:**
- All 3 processes defined in one file
- Workflow at the bottom
- This works fine but isn't reusable

### Step 2: Run the monolithic pipeline

```bash
nextflow run monolithic.nf
```

**Expected:** 9 tasks total (3 SAY_HELLO + 3 CONVERT_TO_UPPER + 3 COUNT_CHARACTERS)

### Step 3: Check the outputs

```bash
# List the results
ls -R results/

# Read one of each type
cat results/greetings/greeting_Alice.txt
cat results/upper/upper_greeting_Alice.txt
cat results/stats/stats_upper_greeting_Alice.txt
```

**Questions to answer:**
1. How many greetings were created? (Should be 3)
2. What does the CONVERT_TO_UPPER process do? (Converts to uppercase)
3. What does COUNT_CHARACTERS output? (Character count with filename)

### Step 4: Test resume on monolithic

```bash
# Run again with resume
nextflow run monolithic.nf -resume
```

**Expected:** All tasks cached (no new work done)

```bash
# Check the log
nextflow log
```

You should see two runs of monolithic.nf

## Part 2: Modular Refactoring (Basic Exercise)

**Objective:** Convert the monolithic pipeline to use modules.

### Step 1: Examine the module structure

```bash
# Look at the directory structure
tree modules/
```

**Expected:**
```
modules/
└── local/
    ├── analyze.nf
    ├── convertToUpper.nf
    ├── countCharacters.nf
    └── sayHello.nf
```

### Step 2: Examine one module

```bash
cat modules/local/sayHello.nf
```

**What to notice:**
- It's just the process definition
- No workflow block
- No channel creation
- Identical to the version in monolithic.nf

### Step 3: Examine the modular main.nf

```bash
cat main.nf
```

**What to notice:**
- `include` statements at the top
- Process names in curly braces
- `from` followed by relative path
- The workflow block looks identical to monolithic version

### Step 4: Run the modular pipeline

```bash
# Clean up from previous run
rm -rf results

# Run modular version
nextflow run main.nf
```

**Expected:** Identical output to monolithic version!

### Step 5: Verify outputs match

```bash
# Compare a file from monolithic run (if you kept it)
# Or just verify the files exist
ls results/greetings/
ls results/upper/
ls results/stats/
```

**Key insight:** Modularization doesn't change functionality, only organization!

### Step 6: Test resume with modular pipeline

```bash
# First run
nextflow run main.nf

# Second run with resume
nextflow run main.nf -resume
```

**Expected:** All cached!

### Step 7: Make a change to test partial resume

```bash
# Edit the SAY_HELLO module to change the greeting
# Change "Welcome to Nextflow" to "Welcome to Module World"

# Using sed:
sed -i 's/Welcome to Nextflow/Welcome to Module World/' modules/local/sayHello.nf

# Or edit manually in your editor

# Run with resume
nextflow run main.nf -resume
```

**Expected:**
- SAY_HELLO re-runs (3 tasks)
- CONVERT_TO_UPPER re-runs (3 tasks) - because input changed
- COUNT_CHARACTERS re-runs (3 tasks) - because input changed

**Key insight:** Changing a module invalidates downstream tasks, but resume still works!

```bash
# Verify the change
cat results/greetings/greeting_Alice.txt
```

Should say "Welcome to Module World"

```bash
# Change it back for consistency
sed -i 's/Welcome to Module World/Welcome to Nextflow/' modules/local/sayHello.nf
```

## Part 3: Process Aliasing (Intermediate Exercise)

**Objective:** Use the same module multiple times with different aliases.

### Step 1: Examine exercise_02.nf

```bash
cat exercise_02.nf
```

**What to notice:**
- Same module imported twice
- Different aliases: `SAY_HELLO_FORMAL` and `SAY_HELLO_CASUAL`
- Both run independently

### Step 2: Run the aliasing example

```bash
nextflow run exercise_02.nf
```

**Expected:**
- 2 tasks for FORMAL
- 2 tasks for CASUAL
- Total 4 tasks

### Step 3: Examine the outputs

```bash
ls results_aliasing/greetings/
cat results_aliasing/greetings/greeting_Alice.txt
```

**Question:** Which one won - FORMAL or CASUAL?

**Answer:** CASUAL (it ran second and overwrote FORMAL's output)

### Step 4: Check the work directories

```bash
# List recent work directories
ls -lt work/??/*/ | head -20
```

**What to notice:**
- Multiple work directories for greeting_Alice.txt
- One from FORMAL, one from CASUAL
- They're independent even though they create the same filename

### Step 5: Inspect both work directories

```bash
# Find the two most recent SAY_HELLO work directories
# They should have identical .command.sh files but different hashes

# Example (adjust the hash):
cat work/aa/bbbbbb*/.command.sh
cat work/cc/dddddd*/.command.sh
```

**Key insight:** Aliasing creates truly independent process instances!

## Part 4: Using bin/ Scripts (Challenge Exercise)

**Objective:** Create and use a helper script from the bin/ directory.

### Step 1: Verify bin/analyze.sh exists and is executable

```bash
ls -lh bin/analyze.sh
```

**Expected:** Should show executable permissions (x flags)

If not:
```bash
chmod +x bin/analyze.sh
```

### Step 2: Test the script manually

```bash
# Create a test input
echo "Hello, World!" > /tmp/test_greeting.txt

# Run the analyze script
bin/analyze.sh /tmp/test_greeting.txt /tmp/test_output.txt

# Check the output
cat /tmp/test_output.txt
```

**Expected output:**
```
=== Greeting Analysis ===
File: test_greeting.txt
Characters: 14
Words: 2
Lines: 1
Enthusiasm: HIGH
```

### Step 3: Examine the ANALYZE_GREETING module

```bash
cat modules/local/analyze.nf
```

**What to notice:**
- Script block calls `analyze.sh` directly
- NO path specified (not `bin/analyze.sh` or `./bin/analyze.sh`)
- Just the script name!

### Step 4: Examine exercise_03.nf

```bash
cat exercise_03.nf
```

**What to notice:**
- Imports SAY_HELLO and ANALYZE_GREETING
- Chains them together
- SAY_HELLO creates greetings, ANALYZE_GREETING analyzes them

### Step 5: Run the bin/ exercise

```bash
nextflow run exercise_03.nf
```

**Expected:**
- 3 SAY_HELLO tasks
- 3 ANALYZE_GREETING tasks
- Total 6 tasks

### Step 6: Examine the analysis outputs

```bash
cat results_binscript/analysis/analysis_greeting_Alice.txt
cat results_binscript/analysis/analysis_greeting_Bob.txt
cat results_binscript/analysis/analysis_greeting_Charlie.txt
```

**What to check:**
- Are character counts correct?
- Is enthusiasm HIGH? (should be - greetings end with !)
- Are word counts 5?

### Step 7: Verify script was automatically copied

```bash
# Find an ANALYZE_GREETING work directory
# Look for the analyze.sh script in it

# Example (adjust hash):
ls work/gg/hhhhhh*/
```

**Expected:** You should see `analyze.sh` in the work directory!

```bash
# Check it's executable
ls -l work/gg/hhhhhh*/analyze.sh
```

### Step 8: Modify the analysis script

```bash
# Add a new analysis metric
# Edit bin/analyze.sh and add before the enthusiasm check:

# Check if name contains 'Alice'
if grep -q 'Alice' "$input_file"; then
    echo "Special Guest: YES" >> "$output_file"
else
    echo "Special Guest: NO" >> "$output_file"
fi
```

**Or use sed:**
```bash
sed -i '/# Check if greeting is enthusiastic/i \
# Check if name contains Alice\
if grep -q "Alice" "$input_file"; then\
    echo "Special Guest: YES" >> "$output_file"\
else\
    echo "Special Guest: NO" >> "$output_file"\
fi\
' bin/analyze.sh
```

### Step 9: Re-run with the modified script

```bash
nextflow run exercise_03.nf -resume
```

**Expected:**
- SAY_HELLO tasks cached (no change)
- ANALYZE_GREETING tasks re-run (script changed!)

```bash
# Check the new output
cat results_binscript/analysis/analysis_greeting_Alice.txt
```

**Expected:** Should now include "Special Guest: YES"

```bash
cat results_binscript/analysis/analysis_greeting_Bob.txt
```

**Expected:** Should include "Special Guest: NO"

**Key insight:** Changes to bin/ scripts invalidate tasks that use them!

## Part 5: Advanced Testing

### Test 1: Multiple includes from same file

**Create test_multiple.nf:**
```nextflow
include { SAY_HELLO; CONVERT_TO_UPPER } from './modules/local/sayHello'

workflow {
    channel.of('Test').set { ch }
    SAY_HELLO(ch)
}
```

```bash
nextflow run test_multiple.nf
```

**Expected:** Error! CONVERT_TO_UPPER is not in sayHello.nf

**Fix it:**
```nextflow
include { SAY_HELLO } from './modules/local/sayHello'
include { CONVERT_TO_UPPER } from './modules/local/convertToUpper'

workflow {
    channel.of('Test').set { ch }
    SAY_HELLO(ch)
}
```

**Key learning:** Each module file should contain only related processes.

### Test 2: Relative path dependencies

```bash
# Try running from a different directory
cd modules/local
nextflow run ../../main.nf
cd ../..
```

**Expected:** Should work! Nextflow resolves paths correctly.

### Test 3: Breaking the cache intentionally

```bash
# Run pipeline
nextflow run main.nf

# Rename a module file
mv modules/local/sayHello.nf modules/local/greeting.nf

# Update include statement
sed -i 's|sayHello|greeting|' main.nf

# Try to resume
nextflow run main.nf -resume
```

**Expected:** Cache invalidated (new work directories created)

**Why:** The import path changed, so Nextflow treats it as a different pipeline

```bash
# Fix it back
mv modules/local/greeting.nf modules/local/sayHello.nf
sed -i 's|greeting|sayHello|' main.nf
```

## Completion Checklist

Mark off as you complete:

- [ ] Ran monolithic.nf successfully
- [ ] Ran main.nf (modular version) successfully
- [ ] Verified resume works with modular pipeline
- [ ] Tested that module changes invalidate downstream tasks
- [ ] Ran exercise_02.nf (process aliasing)
- [ ] Understood why CASUAL overwrites FORMAL
- [ ] Ran exercise_03.nf (bin/ scripts)
- [ ] Verified analyze.sh was automatically available
- [ ] Modified analyze.sh and saw tasks re-run
- [ ] Examined work directories to see copied scripts
- [ ] Read EXPECTED_OUTPUTS.md to verify results
- [ ] Understand the difference between monolithic and modular approaches

## Troubleshooting Common Issues

### "Process SAY_HELLO is not defined"
- Check your include statement
- Verify the module file exists
- Check spelling/capitalization

### "Cannot find module file"
- Check the path in your include statement
- Paths are relative to where you run `nextflow run`
- Make sure you're in the right directory

### "command not found: analyze.sh"
- Check script is in `bin/` directory (not `bins/` or `scripts/`)
- Check script is executable: `chmod +x bin/analyze.sh`
- Check script name spelling in process

### Resume doesn't work
- Did you actually change something?
- Try `nextflow clean -f` to clear cache
- Check if you changed import paths (breaks cache)

### Different output than expected
- Check params (are they the same?)
- Check publishDir settings
- Compare .command.sh files in work directories

## Next Steps

You're now ready for **Session 5: Containers**! You'll learn how to:
- Add container directives to these modules
- Make pipelines portable across systems
- Use Docker, Singularity, and Seqera Containers
- Ensure reproducibility

Keep your Session 4 directory - we'll build on these modules in future sessions!
