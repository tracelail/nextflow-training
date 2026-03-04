# Session 11 — Cache, Resume, and Debugging

**Source material**: training.nextflow.io — Fundamentals: Cache and Resume + Side Quest: Debugging Workflows  
**Nextflow version**: 25.04.6  
**Session type**: Diagnostic and practical  

---

## Learning objectives

After completing this session you will be able to:

- Explain how Nextflow computes a task's 128-bit hash and what factors feed into it
- Use `-resume` correctly and predict which tasks will and will not be cached
- Identify the five most common causes of unexpected cache invalidation — and fix each one
- Navigate a work directory and read `.command.sh`, `.command.err`, and `.exitcode` to diagnose failures
- Use `nextflow log` with `-f` and `-F` flags for execution forensics
- Run `nextflow lint` as the first step in any debugging session (new in 25.04)
- Use `-preview` for dry-run structure validation
- Use `-stub-run` to test workflow logic without real tools
- Debug a buggy pipeline systematically using the four-phase method

---

## Prerequisites

- Sessions 1–10 completed
- Your `nextflow-training/` repository is present
- Nextflow 25.04.6 is active (`nextflow -version` to confirm)
- No containers required — all exercises use plain Bash

---

## How to use this session

```
session11/
├── README.md              ← You are here
├── nextflow.config        ← Shared config for all exercises
├── data/                  ← Synthetic sample data
│   ├── samplesheet.csv
│   ├── sampleA.txt
│   ├── sampleB.txt
│   ├── sampleC.txt
│   └── sampleD.txt
├── exercises/
│   ├── 01_resume_demo.nf       ← Basic: understanding -resume
│   ├── 02_invalidation.nf      ← Intermediate: cache invalidation causes
│   ├── 03_log_forensics.nf     ← Intermediate: nextflow log usage
│   ├── 04_stub_preview.nf      ← Intermediate: stub runs + preview
│   └── 05_buggy_workflow.nf    ← Challenge: find and fix all bugs
├── solutions/
│   └── 05_buggy_workflow_fixed.nf
├── scripts/
│   └── log_template.html       ← For nextflow log -t
└── VERIFICATION.md             ← Expected outputs checklist
```

Copy this session directory into your training repo:

```bash
cp -r session11/ ~/nextflow-training/session11/
cd ~/nextflow-training/session11/
```

---

## Concepts

### How the 128-bit task hash works

Every time Nextflow runs a process, it computes a **128-bit hash** for that task. Think of this hash as a fingerprint. If the fingerprint matches a previously completed task, Nextflow skips it and reuses the cached outputs. If the fingerprint differs, the task runs fresh.

The hash is computed from **13 inputs**, including: the task's script text, all input values and file metadata (path + size + modification timestamp), the container image, any `ext` properties, and scripts in the `bin/` directory. Change any of these and you get a new hash — and a cache miss.

This is why `-resume` is so powerful: even if you crash 90% of the way through a pipeline, `-resume` replays the whole DAG but skips every task whose hash already has a valid cached result.

### The work directory

Every task executes in its own isolated subdirectory under `work/`, named by the first two characters of its hash:

```
work/
└── 7b/
    └── 3753ff13b1fa5348d2d9b6f512153a/
        ├── .command.sh     ← THE script that ran (fully interpolated)
        ├── .command.run    ← Bash wrapper managing the environment
        ├── .command.out    ← Standard output
        ├── .command.err    ← Standard error
        ├── .command.log    ← Combined stdout + stderr
        ├── .command.begin  ← Created when the task starts
        ├── .exitcode       ← Exit code (0 = success)
        └── myoutput.txt    ← Actual output files
```

**When a task fails, the first thing to do is `cd` into its work directory and read these files.**

### The five cache-breakers

| # | Cause | Fix |
|---|-------|-----|
| 1 | Input file touched or moved | Leave input files untouched between runs |
| 2 | Process modifies its own input file | Always write to new output files |
| 3 | NFS timestamp inconsistency | Add `cache 'lenient'` to affected processes |
| 4 | Missing `def` in a closure → race condition | Always declare variables with `def` inside closures |
| 5 | Non-deterministic channel ordering | Use `join` with meta maps to pair results by key |

### The four-phase debugging method

1. **Syntax check (5 min)**: `nextflow lint main.nf` — catches issues before any execution
2. **Quick assessment (5 min)**: `nextflow run workflow.nf -preview` — validates structure without running
3. **Detailed investigation (15–30 min)**: Work directory inspection + `.view()` on channels
4. **Fix and validate (15 min)**: Make targeted changes, re-run with `-resume`

### Exit codes to know

| Code | Meaning | Common cause |
|------|---------|--------------|
| 0 | Success | — |
| 1 | General error | Script logic, Python syntax error |
| 127 | Command not found | Missing tool, wrong container, `bin/` script not executable |
| 137 | Process killed | Exceeded memory or time limit |

---

## Exercise 1 — Basic: Understanding -resume

**Goal**: See exactly which tasks are cached and which re-execute after a code change.

### Step 1: Create the working directory and run the first pipeline

```bash
mkdir -p ~/nextflow-training/session11/
cd ~/nextflow-training/session11/
```

Run the provided `01_resume_demo.nf`:

```bash
nextflow run exercises/01_resume_demo.nf
```

You should see output like:

```
executor >  local (4)
[7b/1a2c3d] REVERSE_TEXT (sampleA) [100%] 1 of 1 ✔
[3c/4d5e6f] REVERSE_TEXT (sampleB) [100%] 1 of 1 ✔
[8f/9a0b1c] REVERSE_TEXT (sampleC) [100%] 1 of 1 ✔
[2d/3e4f5a] COUNT_WORDS  (sampleA) [100%] 1 of 1 ✔
```

Note the two-character work directory prefixes in brackets — these are the first two characters of each task's hash.

### Step 2: Re-run with -resume (nothing changed)

```bash
nextflow run exercises/01_resume_demo.nf -resume
```

Expected output — all tasks should be cached:

```
executor >  local (0)
[7b/1a2c3d] REVERSE_TEXT (sampleA) [100%] 1 of 1, cached: 1 ✔
[3c/4d5e6f] REVERSE_TEXT (sampleB) [100%] 1 of 1, cached: 1 ✔
[8f/9a0b1c] REVERSE_TEXT (sampleC) [100%] 1 of 1, cached: 1 ✔
[2d/3e4f5a] COUNT_WORDS  (sampleA) [100%] 1 of 1, cached: 1 ✔
```

The phrase `cached: 1` confirms the task was skipped and the previous result reused. The work directory hash prefix is **identical** to the first run — same inputs, same hash, same cache entry.

### Step 3: Change only one process and resume

Open `exercises/01_resume_demo.nf`. Find the `COUNT_WORDS` process. Change:

```groovy
// BEFORE
echo "Words: $(wc -w < ${text})"

// AFTER
echo "Word count for ${meta.id}: $(wc -w < ${text})"
```

Now re-run with `-resume`:

```bash
nextflow run exercises/01_resume_demo.nf -resume
```

Expected: `REVERSE_TEXT` tasks are still cached (their hash didn't change). `COUNT_WORDS` re-executes with a new hash (its script changed). This is the most important lesson: **Nextflow re-evaluates the whole DAG but only re-executes tasks whose hash changed**.

### Step 4: Inspect a work directory

Find the work directory for one REVERSE_TEXT task from the output (e.g., `[7b/1a2c3d]`):

```bash
# Use the prefix to navigate (tab completion works)
ls -la work/7b/1a2c3d*/

# Read the actual script that ran
cat work/7b/1a2c3d*/.command.sh

# Check the exit code
cat work/7b/1a2c3d*/.command.sh
cat work/7b/1a2c3d*/.exitcode
```

**Question to answer**: Does `.command.sh` show Nextflow variable names like `${meta.id}` or the resolved values like `sampleA`? (Hint: it shows resolved values — this is the interpolated script.)

---

## Exercise 2 — Intermediate: Triggering cache invalidation

**Goal**: Deliberately break the cache in four different ways and observe what happens.

Run `exercises/02_invalidation.nf` as the starting point:

```bash
nextflow run exercises/02_invalidation.nf
```

### Invalidation experiment A: Touch an input file

```bash
# "Touch" sampleA.txt — updates its modification timestamp without changing content
touch data/sampleA.txt

# Resume — what happens?
nextflow run exercises/02_invalidation.nf -resume
```

Expected: The task that uses `sampleA.txt` re-executes even though the file content is identical. The hash changed because the modification timestamp changed.

**Fix**: Add `cache 'lenient'` to the process directive to ignore timestamps:

```groovy
process PROCESS_SAMPLE {
    cache 'lenient'     // Only hashes path + size, ignores timestamp
    ...
}
```

After adding this, touch the file again and resume — the task should now stay cached.

### Invalidation experiment B: The missing `def` race condition

Look at `exercises/02_invalidation.nf` — there is a section demonstrating the race condition. Run it several times:

```bash
nextflow run exercises/02_invalidation.nf -resume
nextflow run exercises/02_invalidation.nf -resume
nextflow run exercises/02_invalidation.nf -resume
```

Observe that the `COMBINE_RESULTS` task sometimes gets different inputs depending on which concurrent map closure happened to write to the shared variable last. This breaks resume because the task hash changes between runs.

**Fix**: Add `def` before the variable declaration inside the closure. The corrected version is shown in the exercise file's comments.

### Invalidation experiment C: Non-deterministic channel ordering

The `exercises/02_invalidation.nf` pipeline has two processes that use `sleep` with random durations, then feed a third process. Run it multiple times and use `nextflow log` to compare:

```bash
nextflow run exercises/02_invalidation.nf

# List recent runs
nextflow log

# Compare task inputs between runs
nextflow log <run_name_1> -f 'process,tag,hash'
nextflow log <run_name_2> -f 'process,tag,hash'
```

You will observe that `REVERSE_TEXT` and `COUNT_WORDS` have stable hashes (same inputs each time) but `COMBINE_RESULTS` has a different hash each run because its inputs arrive in non-deterministic order.

**Fix**: Use `join` with the meta map to pair results by key rather than relying on channel ordering.

---

## Exercise 3 — Intermediate: nextflow log forensics

**Goal**: Master `nextflow log` for investigating past executions.

### Step 1: Run the forensics pipeline

```bash
nextflow run exercises/03_log_forensics.nf
```

This pipeline intentionally processes 6 samples through 3 processes with varying durations.

### Step 2: List all past executions

```bash
nextflow log
```

Note the run name in the `RUN NAME` column (e.g., `happy_curie`).

### Step 3: List all tasks for a specific run

```bash
nextflow log happy_curie
```

You will see a list of work directory paths, one per task.

### Step 4: Select specific fields

```bash
# See process name, exit code, hash, and duration
nextflow log happy_curie -f 'process,exit,hash,duration'

# See full command script
nextflow log happy_curie -f 'name,script'

# See work directory and status
nextflow log happy_curie -f 'name,status,workdir'
```

### Step 5: Filter tasks by expression

```bash
# Show only tasks from a specific process
nextflow log happy_curie -F 'process =~ /REVERSE.*/'

# Show only successful tasks
nextflow log happy_curie -F 'status == "COMPLETED"'

# Show tasks that took more than 1 second
nextflow log happy_curie -F 'duration > 1000'
```

### Step 6: Generate an HTML provenance report

```bash
nextflow log happy_curie -t scripts/log_template.html > expected_outputs/provenance.html
```

Open `expected_outputs/provenance.html` in a browser. You will see a formatted card for each task showing its script, exit code, status, and work directory.

---

## Exercise 4 — Intermediate: Stub runs and preview mode

**Goal**: Use `-preview` and `-stub-run` to validate workflow logic without executing real commands.

### Step 1: Lint first (always)

```bash
nextflow lint exercises/04_stub_preview.nf
```

Fix any warnings before proceeding. Note that `nextflow lint` will flag `Channel.of()` (capital C) and any closures using implicit `it`.

### Step 2: Preview the workflow structure

```bash
nextflow run exercises/04_stub_preview.nf -preview
```

Expected output:

```
Nextflow 25.04.6 preview mode
  [Would execute] SIMULATE_ALIGNMENT (sampleA)
  [Would execute] SIMULATE_ALIGNMENT (sampleB)
  [Would execute] SIMULATE_ALIGNMENT (sampleC)
  [Would execute] SUMMARIZE_RESULTS
No tasks executed (preview mode)
```

Preview mode is faster than a real run and catches structural issues like channels connected to the wrong process inputs.

### Step 3: Run in stub mode

```bash
nextflow run exercises/04_stub_preview.nf -stub-run
```

Each process's `stub:` block executes instead of its `script:` block. The stub creates empty placeholder files using `touch`, satisfying the `output:` declaration without running any real bioinformatics tools.

Check the results:

```bash
ls results/
cat results/*.summary
```

The output files exist but are empty — that is correct for stub mode. The important thing is that the **channel wiring worked**: data flowed through all three processes in the right order, metadata was propagated correctly, and the collect/aggregation step received all expected inputs.

### Step 4: Add your own stub block

Open `exercises/04_stub_preview.nf`. The `SUMMARIZE_RESULTS` process does not yet have a `stub:` block. Add one:

```groovy
stub:
"""
touch summary_report.txt
"""
```

Re-run with `-stub-run` and confirm the summary file now appears in results.

---

## Exercise 5 — Challenge: Debug the buggy workflow

**Goal**: Find and fix all bugs in `exercises/05_buggy_workflow.nf` using the four-phase method.

This is the capstone exercise. The file contains **8 deliberate bugs** spanning syntax errors, logic errors, channel shape mismatches, and a race condition. Do not look at the solution file until you have attempted all four phases.

### Phase 1 — Lint (do this first)

```bash
nextflow lint exercises/05_buggy_workflow.nf
```

Record every warning and error. Some bugs will appear here; others only manifest at runtime.

### Phase 2 — Preview

```bash
nextflow run exercises/05_buggy_workflow.nf -preview
```

Some structural issues only appear at parse time. Note any errors that did not appear in the lint output.

### Phase 3 — Stub run

```bash
nextflow run exercises/05_buggy_workflow.nf -stub-run
```

Logic bugs and channel shape mismatches typically appear here. When a task fails in stub mode, navigate to its work directory:

```bash
# Get the work directory from the error output, e.g. [ab/12cdef]
cat work/ab/12cdef*/.command.sh
cat work/ab/12cdef*/.command.err
cat work/ab/12cdef*/.exitcode
```

### Phase 4 — Full run with -resume

Once all stub-run bugs are fixed, attempt a real run:

```bash
nextflow run exercises/05_buggy_workflow.nf
```

Fix remaining failures and use `-resume` to avoid re-running already-passing tasks.

### Bug inventory (fill in as you find them)

Keep notes as you work through the exercise:

| # | Phase found | Location | Bug description | Fix applied |
|---|-------------|----------|----------------|-------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |

When you have fixed all bugs, the pipeline should complete successfully with:

```
executor >  local (8)
[xx/xxxxxx] PREPARE_SAMPLES  (sampleA) [100%] 4 of 4 ✔
[xx/xxxxxx] ANALYZE_SAMPLE   (sampleA) [100%] 4 of 4 ✔
[xx/xxxxxx] AGGREGATE_RESULTS           [100%] 1 of 1 ✔
Pipeline completed. Check results/final_report.txt
```

Compare your fixed file against `solutions/05_buggy_workflow_fixed.nf`.

---

## Debugging tips

**"No such file or directory" in .command.err**
The process script references a file that wasn't staged into the work directory. Check that the `input:` block declares the file and that the variable name in the script matches. Exit code will be 127 or 1.

**"WARN: Task cached status may be inaccurate"**
This appears on NFS file systems. Add `cache 'lenient'` to affected processes to ignore timestamps.

**Tasks keep re-running even with -resume**
Use `nextflow -log debug.log run workflow.nf -resume -dump-hashes` then search `debug.log` for `MISS` to find which hash component changed.

**Channel hangs — pipeline never completes**
A `groupTuple` is waiting for elements that never arrive, or a `join` has a key mismatch. Add `.view { "DEBUG: $it" }` before the hanging operator to inspect what's actually flowing through the channel.

**Exit code 127 on every task**
The command isn't on PATH. Either `-profile docker` wasn't specified, the container image name is wrong, or a `bin/` script isn't executable (`chmod +x bin/myscript.sh`).

**Race condition: pipeline gives different results each run**
A variable is declared inside a closure without `def`. Run `nextflow lint` — it will flag undeclared variables. Add `def` before every variable inside closures.

---

## Key takeaways

Nextflow's caching system is deterministic: the same inputs always produce the same 128-bit hash, and the same hash always hits the same cache entry. When resume behaves unexpectedly, the cause is always traceable to one of five specific patterns — input file metadata changed, a process modified its input, NFS timestamps are inconsistent, a missing `def` created a race condition, or channel ordering is non-deterministic.

The 25.04-era toolchain creates a clear escalation ladder for debugging: `nextflow lint` catches syntax issues statically, `-preview` validates workflow structure without execution, and `-stub-run` tests data flow without real tools — so that by the time you attempt a real run, only genuine computational issues remain.

Work directory inspection is the single most powerful diagnostic technique available: `.command.sh` shows exactly what ran, `.command.err` shows why it failed, and `.exitcode` tells you the severity. Every Nextflow failure leaves a complete forensic record — the challenge is knowing where to look.
