# Session 18 — Strict Syntax and the 2026 Nextflow Language

> **Nextflow version required:** 25.10.x (you have 25.10.4 ✓)  
> **Source reference:** [nextflow.io/docs/latest/strict-syntax.html](https://nextflow.io/docs/latest/strict-syntax.html)  
> **No training.nextflow.io equivalent — this is new 2026 material**

---

## Learning objectives

After completing this session you will be able to:

- Enable `NXF_SYNTAX_PARSER=v2` and understand what it changes
- Run `nextflow lint` to identify every strict-syntax violation in a pipeline
- Convert all deprecated and banned patterns to their 2026-correct equivalents
- Add a typed `params {}` block to a pipeline script
- Add `onComplete:` and `onError:` sections to an entry workflow
- Explain *why* each rule exists, not just what replaces it

---

## Prerequisites

- Sessions 1–17 completed
- Session 14 pipeline directory available (the nf-core template pipeline you
  created). If you no longer have it, a self-contained starter pipeline is
  provided in `exercises/starter_pipeline/` — it contains the same patterns
  you would encounter in the Session 14 output.
- `nextflow` 25.10.4 on your PATH
- `NXF_SYNTAX_PARSER` **not yet set** (you will set it during the exercises)

---

## Background: why strict syntax exists

Nextflow grew out of Groovy, which gave it enormous power but also a problem: any
valid Groovy code was also valid Nextflow. That made it hard to give helpful error
messages, hard to build editor tooling, and impossible to introduce Nextflow-specific
language features cleanly.

The v2 parser solves this by implementing a **purpose-built Nextflow parser** that
only accepts a controlled subset of the language. When something goes wrong it can
say *"process input must be `val`, `path`, or `tuple`"* rather than *"unexpected
token on line 42"*.

This matters practically: starting with Nextflow **26.04.0** (expected April 2026),
`NXF_SYNTAX_PARSER=v2` becomes the **default**. nf-core mandates it **Q2 2026**.
Pipelines written today that pass `nextflow lint` will need zero changes at that
transition. Pipelines that don't will break.

### The three tiers of changes

| Tier | Effect now | Effect at 26.04 |
|------|-----------|-----------------|
| **Removed** (e.g. `import`, `for` loops, `switch`) | Hard error with `v2` | Hard error |
| **Deprecated** (e.g. `Channel.of`, implicit `it`) | Warning with `v2` | Hard error |
| **New features** (typed params, `onComplete:` sections) | Only available with `v2` | Default |

---

## Concepts

### What gets banned and why

**No `import` statements.**  
Strict syntax doesn't use the Groovy compiler, so the Java class-loading mechanism
that powers `import` isn't available. Use fully qualified names instead:
`new groovy.json.JsonSlurper()` rather than importing and then using `JsonSlurper()`.

**No `for`/`while`/`switch`.**  
These are imperative loop constructs that belong in scripting contexts. Nextflow
channels are dataflow — data transformation belongs in closures (`.map`, `.filter`,
`.collect`, `.each`). Replacing a `switch` with `if`/`else if` chains is a
mechanical one-for-one substitution.

**No implicit `it`.**  
Writing `{ it.id }` works in standard Groovy because `it` is the implicit single
parameter of a closure. The v2 parser bans it because it makes code harder to read
and harder for tooling to analyse. `{ sample -> sample.id }` is no harder to write
and considerably easier to understand six months later.

**No top-level statements mixed with declarations.**  
A Nextflow script is either a *snippet* (executable statements only) or a *module*
(declarations — processes, workflows, functions — only). Mixing them was always
semantically odd; strict syntax makes the rule explicit.

**Lowercase `channel`.**  
`Channel.of()` vs `channel.of()` is purely cosmetic but it signals the shift: channel
factories are now part of the Nextflow language, not a Groovy class you happen to
call. The lowercase form has been correct since Nextflow 20.07 and is now enforced.

### The typed `params {}` block (new in 25.10)

Before strict syntax, `params` lived in a config file or as scattered `params.x = y`
assignments. The typed block centralises them in the script with types:

```nextflow
params {
    input:  Path                           // required — no default
    outdir: Path    = 'results'            // optional — has default
    save_all: Boolean = false
}
```

- Parameters **without a default are required** — the pipeline errors at startup if they
  aren't provided.
- Type annotations give automatic CLI coercion: `--save_all true` is parsed as a
  Boolean, not a String.
- A `params {}` block may only appear in script files, not in `nextflow.config`.

### The `onComplete:` / `onError:` sections (new in 25.10)

In standard DSL2, workflow completion handlers were top-level statements:

```nextflow
workflow.onComplete { println "Done!" }
```

This is banned in strict mode (top-level statement mixed with declarations).
In 25.10 the idiomatic replacement is a named section inside the entry workflow:

```nextflow
workflow {
    main:
    // your pipeline logic

    onComplete:
    log.info "Pipeline finished at $workflow.complete"

    onError:
    log.error "Pipeline failed: ${workflow.errorMessage}"
}
```

---

## Hands-on exercises

### Exercise 1 — Enable strict mode and run `nextflow lint` (Basic)

**Goal:** See what a real pipeline looks like through the strict syntax lens.

**Step 1.** Open a terminal and navigate to your Session 14 pipeline directory
(or use the provided starter):

```bash
cd ~/nf-training/session14   # your Session 14 directory
# OR
cd path/to/session18/exercises/starter_pipeline
```

**Step 2.** Run `nextflow lint` *without* enabling strict mode — this uses the same
parser but gives you a report:

```bash
nextflow lint .
```

Read the output carefully. Each line identifies a file, a line number, and a
description of the problem.

**Step 3.** Also try with concise output to get a summary:

```bash
nextflow lint -o concise .
```

**Expected output shape:**
```
/path/to/main.nf:12:1: warning: the use of 'Channel' is deprecated ...
/path/to/main.nf:25:9: warning: implicit closure parameter 'it' ...
/path/to/workflows/pipeline.nf:8:1: warning: the use of 'Channel' is ...
```

**What to do with this output:**
Write down all the files and line numbers flagged. Group them by category:
- `Channel` → `channel`
- implicit `it`
- top-level statements
- `shell:` block
- anything else

You will fix each category in Exercise 2 and 3.

---

### Exercise 2 — Fix deprecated syntax (Basic → Intermediate)

Work through your lint report and apply the following substitutions. Do one
file at a time. After each file, re-run `nextflow lint <filename>` to verify.

**2a. `Channel` → `channel` (all factory methods)**

Open each file flagged. Search for `Channel.` and replace:

```nextflow
// BEFORE:
reads_ch = Channel.fromPath(params.input)
empty_ch  = Channel.empty()
value_ch  = Channel.value('hello')

// AFTER:
reads_ch = channel.fromPath(params.input)
empty_ch  = channel.empty()
value_ch  = channel.value('hello')
```

**2b. Implicit `it` → explicit closure parameter**

Search for closures that use `it` without declaring a name. Look for `{ it.` or
`{ !{it` patterns:

```nextflow
// BEFORE:
samples_ch.map { [it.id, file(it.fastq_1), file(it.fastq_2)] }
reads_ch.filter { it.size() > 0 }
ch.view { "Sample: ${it}" }

// AFTER:
samples_ch.map { row -> [row.id, file(row.fastq_1), file(row.fastq_2)] }
reads_ch.filter { reads -> reads.size() > 0 }
ch.view { v -> "Sample: ${v}" }
```

**2c. `workflow.onComplete` top-level handler**

Find any lines like `workflow.onComplete { ... }` outside a workflow block and
move them inside the entry workflow using the section syntax:

```nextflow
// BEFORE (top-level — banned):
workflow.onComplete {
    println "Pipeline completed!"
}

// AFTER (inside entry workflow):
workflow {
    main:
    // ... existing pipeline calls ...

    onComplete:
    log.info "Pipeline completed at $workflow.complete"
}
```

**2d. `shell:` block → `script:` block**

Replace any `shell:` blocks. The key difference: inside `shell:`, Nextflow
variables were `!{var}` and Bash variables were `$var`. Inside `script:`,
Nextflow variables are `${var}` and Bash variables need to be escaped as `\$var`
or placed in single-quoted sections:

```nextflow
// BEFORE (shell block):
shell:
'''
echo "Sample: !{meta.id}"
echo "Threads: $THREADS"
'''

// AFTER (script block):
script:
def sample_id = meta.id
"""
echo "Sample: ${sample_id}"
echo "Threads: \$THREADS"
"""
```

After completing 2a–2d, run `nextflow lint .` again. The warning count should
be zero or very close to zero.

---

### Exercise 3 — Enable NXF_SYNTAX_PARSER=v2 and fix errors (Intermediate)

**Step 1.** Export the environment variable:

```bash
export NXF_SYNTAX_PARSER=v2
```

**Step 2.** Re-run lint. With the v2 parser enabled you may see additional
**errors** (not just warnings) for things the standard linter only warned about:

```bash
nextflow lint .
```

**Step 3.** Try running the pipeline with a dry-run (stub mode) to see if it
parses cleanly end-to-end:

```bash
nextflow run main.nf -stub -profile test 2>&1 | head -40
```

**Common errors you may encounter and how to fix them:**

**Error: `Unexpected statement at top-level`**  
You have executable code (e.g. `println`, variable assignment) outside any
process or workflow. Wrap it in a workflow block or delete it.

**Error: `Unknown variable 'Channel'`**  
You missed a `Channel.` → `channel.` substitution. The v2 parser doesn't know
about the `Channel` class at all.

**Error: `env output name must be quoted`**  
Find any `env FOO` in output blocks and change to `env 'FOO'`.

**Error involving `import`**  
Remove the import statement and replace with a fully qualified class name.

Keep iterating: fix the first error, re-lint, fix the next. `nextflow lint` only
reports one file's errors at a time in some output modes — use `-o concise` to
see all files at once.

---

### Exercise 4 — Add a typed `params {}` block (Intermediate)

**Goal:** Replace your scattered `params.x = y` declarations with a typed block.

**Step 1.** Open `nextflow.config` (or wherever your params defaults live) and
make a list of every `params.*` key defined there, noting the type of each value:

```
params.input      = null        → Path (required, no default)
params.outdir     = 'results'   → Path
params.multiqc_title = false    → String (or Boolean?)
```

**Step 2.** In `main.nf`, **above** the `include` statements, add a `params {}`
block. Start with your core required parameter and two optional ones:

```nextflow
params {
    // Path to input samplesheet.
    input: Path

    // Directory for published results.
    outdir: Path = 'results'

    // Title for MultiQC report.
    multiqc_title: String = ''
}
```

**Step 3.** Remove the corresponding `params.x = y` lines from `nextflow.config`
(keeping the ones not yet in the block — you can migrate them one at a time).

**Step 4.** Run lint again:

```bash
nextflow lint main.nf
```

**Step 5.** Test that a missing required parameter gives a clear error:

```bash
nextflow run main.nf -stub  # should fail: 'input' is required
nextflow run main.nf -stub --input samplesheet.csv  # should proceed
```

**What you should observe:** The error message when `--input` is missing will be
something like `Missing required parameter: input`. Compare this to the error you
used to get (usually a confusing NullPointerException deep in the pipeline).

---

### Exercise 5 — Add workflow `onComplete:` and `onError:` sections (Intermediate)

**Goal:** Replace any completion handlers with the new section syntax and add an
error handler.

Open your entry workflow (usually in `main.nf` or `workflows/pipeline.nf`).

**Step 1.** If you already have a `workflow.onComplete` (from Session 14 or the
template), remove it.

**Step 2.** Add `main:`, `onComplete:`, and `onError:` sections to the entry workflow.
The `main:` label is required when the workflow body contains named sections:

```nextflow
workflow {

    main:
    //
    // Validate inputs (from nf-schema)
    //
    samplesheetToList(params.input, "${projectDir}/assets/schema_input.json")
        .set { ch_samplesheet }

    //
    // Run the pipeline subworkflow
    //
    PIPELINE(
        ch_samplesheet
    )

    onComplete:
    log.info """\
        =========================================
        Pipeline completed!
        =========================================
        Workflow : ${workflow.scriptName}
        Completed: ${workflow.complete}
        Duration : ${workflow.duration}
        Success  : ${workflow.success}
        Work dir : ${workflow.workDir}
        Exit code: ${workflow.exitStatus}
        =========================================
        """.stripIndent()

    onError:
    log.error """\
        =========================================
        Pipeline FAILED
        =========================================
        Error msg: ${workflow.errorMessage}
        Work dir : ${workflow.workDir}
        =========================================
        """.stripIndent()
}
```

**Step 3.** Run lint to confirm no errors:

```bash
nextflow lint main.nf
```

**Step 4.** Run in stub mode to confirm the pipeline executes and the
`onComplete` message appears at the end:

```bash
nextflow run main.nf -stub -profile test 2>&1 | tail -20
```

---

### Exercise 6 — Challenge: Full strict-mode run with type annotations

**Goal:** Add Nextflow-style type annotations to workflow takes/emits and verify
the pipeline runs cleanly end-to-end under strict syntax.

**Step 1.** Open a sub-workflow file (e.g. `workflows/pipeline.nf` or your
`subworkflows/local/` directory). Add `take:` and `emit:` type annotations:

```nextflow
workflow PIPELINE {

    take:
    samplesheet: Channel  // queue channel of [meta, reads] tuples

    main:
    // ... existing process calls ...

    emit:
    multiqc_report: Channel = MULTIQC.out.report
    versions:       Channel = ch_versions
}
```

**Step 2.** Run lint on the sub-workflow file:

```bash
nextflow lint workflows/pipeline.nf
```

**Step 3.** Run a full stub test end-to-end:

```bash
nextflow run main.nf -stub -profile test --outdir results_test
```

You should see the pipeline complete with zero errors and the `onComplete` banner
printed at the end.

**Step 4.** Verify resume still works — run a second time with `-resume` and
confirm cached tasks are reused:

```bash
nextflow run main.nf -stub -profile test --outdir results_test -resume
```

---

## Debugging tips

**"I have so many lint errors I don't know where to start."**  
Use `-o concise` to count how many per file. Fix all `Channel` → `channel` issues
first (they're mechanical and numerous). Then tackle implicit `it`. The remaining
errors are usually a handful of specific cases.

**"`nextflow lint` says there are no errors but `nextflow run` still fails."**  
The lint command validates syntax but not runtime logic. Check that you haven't
accidentally removed a `def` keyword or changed a variable name during refactoring.
Look at `.command.err` in the work directory.

**"My `onComplete:` section refers to `workflow.complete` but I get a null."**  
The `workflow` object is fully populated only after all tasks finish. Inside
`onComplete:`, you have access to `workflow.complete`, `workflow.success`,
`workflow.duration`, `workflow.exitStatus`, `workflow.errorMessage`, and
`workflow.workDir`. You do *not* have access to channel outputs.

**"I converted a `shell:` block to `script:` and now my Bash variables are
interpolated by Nextflow."**  
Escape dollar signs for Bash variables: `\$VAR` or use single quotes for
sub-sections that should not be interpolated. Alternatively, capture Bash output
in a variable before the heredoc.

**"The typed `params {}` block says my parameter is missing even though it's in
my config file."**  
The params block in the *script* declares parameter types. The config file still
needs to *set* their values. Check that the config file line is `params.input =
'/path/to/file'` (not `params { input = ... }` — the block syntax in config is
different from the typed block syntax in scripts).

**"`env 'FOO'` is causing a lint error about quotes."**  
Make sure you are using single quotes, not backticks or double quotes:
`env 'MY_VAR'` not `env "MY_VAR"`.

---

## Key takeaways

1. **`nextflow lint` is your migration tool.** Run it before and after every
   change. It catches issues without executing a single task.

2. **The changes are mechanical, not conceptual.** Every banned construct has a
   direct, readable replacement. `Channel` → `channel`, `{ it.x }` →
   `{ row -> row.x }`, `for` → `.each {}`, `switch` → `if/else`.

3. **Typed params and workflow sections are the payoff.** Once you've cleared the
   warnings, you gain required-parameter enforcement, type-checked CLI arguments,
   and cleaner completion handlers — features that make pipelines more robust and
   easier to debug.
