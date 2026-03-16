# Session 15 — nf-core Modules: Installing and Using Community Components

**Source material:** [Hello nf-core Part 3](https://training.nextflow.io/2.8.1/hello_nf-core/03_use_module/) · nf-core tools 3.5.2  
**Prerequisite sessions:** 8 (meta map), 13 (running nf-core pipelines), 14 (pipeline structure)  
**Time estimate:** 2–3 hours

---

## Learning objectives

By the end of this session you will be able to:

1. Find and inspect community modules using `nf-core modules list` and `nf-core modules info`
2. Install modules into a pipeline with `nf-core modules install`
3. Read a module's `main.nf` and understand every section: `tag`, `label`, `container`, `input`, `output`, `when`, `script`, `stub`
4. Wire installed modules into a workflow — both the per-sample pattern (FASTQC) and the aggregation pattern (MULTIQC)
5. Configure module behaviour via `ext.args` in `conf/modules.config` without touching module source code
6. Track local module modifications with `nf-core modules patch`

---

## Prerequisites — what should exist before this session

```
session15/
├── assets/samplesheet.csv       ← 4 paired-end samples
├── data/                        ← 8 synthetic .fastq.gz files
├── modules/nf-core/             ← populated by nf-core modules install
├── conf/modules.config          ← ext.args configuration
├── nextflow.config              ← profiles and params
└── main.nf                      ← pipeline entry point
```

The `modules/nf-core/` directory in this training bundle contains pre-downloaded
copies of FASTQC and MULTIQC for reference. **In real development you would
delete these and run `nf-core modules install` yourself.** See Step 2 below.

---

## Concepts

### What is an nf-core module?

An nf-core module is a **standardised, peer-reviewed Nextflow process** maintained
by the community in the [nf-core/modules](https://github.com/nf-core/modules) repository.
There are over 1,400 modules covering tools from FASTQC to STAR to Samtools.

Using community modules instead of writing your own processes gives you:
- Tested, working process definitions you don't have to write
- Pinned container images (Docker + Singularity) for every tool version
- Consistent input/output signatures that compose predictably
- Automatic version reporting

A module is a **directory** (not a single file) with four components:

```
modules/nf-core/fastqc/
├── main.nf           ← The Nextflow process (this is what you include)
├── meta.yml          ← Human/machine-readable documentation of I/O
├── environment.yml   ← Conda dependencies (also used by Seqera Containers/Wave)
└── tests/            ← nf-test files (covered in Session 12)
```

### The two fundamental module input patterns

Every nf-core module fits one of two patterns. **You need to know both.**

**Pattern 1 — Per-sample processing (e.g., FASTQC, TRIMGALORE, BWA_MEM)**

```
input:
tuple val(meta), path(reads)
```

The `meta` map travels *with* the data through every process. It carries sample
identity (`meta.id`), library type (`meta.single_end`), and anything else you
added to it. The output mirrors this:

```
output:
tuple val(meta), path("*.html"), emit: html
tuple val(meta), path("*.zip") , emit: zip
```

**Pattern 2 — Aggregation (e.g., MULTIQC, custom report generators)**

```
input:
path multiqc_files, stageAs: "?/*"
path(multiqc_config)
...
```

No `meta` map. This process runs **once for the whole pipeline**, consuming
output collected from all samples. Its outputs are also plain paths:

```
output:
path "*multiqc_report.html", emit: report
path "*_data"              , emit: data
```

### The ext.args pattern — configuring without touching module code

This is the most important pattern in nf-core module usage.

nf-core modules are **shared code**. You cannot edit them to add your tool flags
because that would break reproducibility and make updates painful. Instead, every
module reads `task.ext.args` and appends it to the command:

```groovy
// Inside modules/nf-core/fastqc/main.nf (you don't write this):
def args = task.ext.args ?: ''
"""
fastqc $args --threads $task.cpus ${reads}
"""
```

You supply the flags from your pipeline's `conf/modules.config`:

```groovy
// Inside conf/modules.config (you DO write this):
process {
    withName: 'FASTQC' {
        ext.args = { '--quiet --noextract' }
    }
}
```

The value **must be a closure** (wrapped in `{ }`) so it evaluates at runtime
and can reference `meta`, `params`, and `task`. This is a critical difference
from regular process config — plain strings evaluate at parse time and cannot
access runtime variables.

Three `ext` directives exist:
- `ext.args` — command-line arguments injected into the tool call
- `ext.prefix` — controls output file naming (used inside the module as `def prefix = task.ext.prefix ?: "${meta.id}"`)
- `ext.when` — conditional execution (`ext.when = { !params.skip_fastqc }`)

### modules.json — the reproducibility lock file

When you install a module, nf-core creates/updates `modules.json` at the root
of your pipeline. It records the exact git commit SHA for every installed module:

```json
{
    "repos": {
        "https://github.com/nf-core/modules.git": {
            "modules": {
                "nf-core": {
                    "fastqc": {
                        "branch": "master",
                        "git_sha": "a3bb0aa...",
                        "installed_by": ["modules"]
                    }
                }
            }
        }
    }
}
```

This SHA pins the module version. Someone running `nf-core modules install` on
another machine gets the **identical code**. This is what makes nf-core pipelines
reproducible across time and environments.

---

## Hands-on exercises

### Setup: navigate to the session directory

```bash
cd /home/trace/projects/nextflow-training/session15
```

---

### Step 1 — Explore the module registry

Before installing anything, browse what's available.

```bash
# List all available modules (1,400+)
nf-core modules list remote

# Filter to just fastq-related modules
nf-core modules list remote | grep -i fastq

# Get detailed info about the FASTQC module
# This shows: description, tool version, exact input/output signatures,
# container image, and the install command
nf-core modules info fastqc
```

Read the output of `nf-core modules info fastqc` carefully. Notice:
- The **input** signature: `tuple val(meta), path(reads)`
- The **output** signatures: `html`, `zip`, `versions`
- The suggested `include` statement at the bottom

**Question:** Based on the info output, what is `meta` expected to contain?
What happens if `meta.single_end` is true?

---

### Step 2 — Install FASTQC and MULTIQC

```bash
# Install from the session15/ directory
nf-core modules install fastqc
nf-core modules install multiqc
```

Each command will:
1. Download the module files into `modules/nf-core/<tool>/`
2. Create or update `modules.json`
3. Print the exact `include` statement to use

After installing, verify what was created:

```bash
# Check what was installed
nf-core modules list local

# Inspect the module directory structure
ls -la modules/nf-core/fastqc/
ls -la modules/nf-core/multiqc/

# Read the FASTQC process definition
cat modules/nf-core/fastqc/main.nf

# Read the MULTIQC process definition — notice NO tuple val(meta) in input
cat modules/nf-core/multiqc/main.nf
```

**Key things to notice in `fastqc/main.nf`:**
- `tag "${meta.id}"` — logs show sample ID instead of a generic hash
- `label 'process_medium'` — maps to resource classes in `nextflow.config`
- `conda "${moduleDir}/environment.yml"` — uses the module's own env file
- Both `script:` and `stub:` blocks exist

**Key things to notice in `multiqc/main.nf`:**
- No `tag` — this process doesn't operate per-sample
- Input is `path multiqc_files, stageAs: "?/*"` — no `val(meta)` at all
- `stageAs: "?/*"` — stages files into numbered subdirectories so tools from
  different processes don't collide even when they produce same-named files
  (e.g., multiple `versions.yml` files)

---

### Step 3 — Basic exercise (FASTQC only)

Open `exercises/01_basic/main.nf` and complete the tasks marked with `???`.

```bash
# After completing the exercise:
nextflow run exercises/01_basic/main.nf -profile docker
```

Expected: 4 FASTQC tasks run in parallel, HTML paths printed to console.

If you get stuck, re-read the `nf-core modules info fastqc` output and compare
the include path carefully. **Do not look at solution.nf yet.**

---

### Step 4 — Read the main pipeline

Once the basic exercise is working, read `main.nf` in this directory.
It is the complete pipeline with detailed comments explaining every decision.

Pay close attention to the channel transformation between FASTQC and MULTIQC:

```groovy
// FASTQC.out.zip emits: [ meta, [zip_file1, zip_file2] ]  (one tuple per sample)
//
// MULTIQC needs:         [ zip1, zip2, zip3, zip4, ... ]  (one flat list of ALL files)
//
// The transformation:
ch_multiqc_files = FASTQC.out.zip
    .map  { meta, zips -> zips }   // strip meta, keep only files
    .collect()                      // gather all 4 samples into one list
```

**Why does MULTIQC need `.collect()` before it runs?**

Nextflow channels emit items as they're ready. Without `.collect()`, MULTIQC
would receive one zip file at a time and run four separate times, each producing
a single-sample report. `.collect()` blocks until ALL emissions are complete,
then delivers the full list as a single item — so MULTIQC runs exactly once.

---

### Step 5 — Run the complete pipeline

```bash
# With Docker:
nextflow run main.nf -profile docker

# Without containers (stub mode — tests wiring, no real tools needed):
nextflow run main.nf -stub
```

Check the results:

```bash
ls results/fastqc/      # 4 HTML reports
ls results/multiqc/     # multiqc_report.html + multiqc_data/
```

Open `results/multiqc/multiqc_report.html` in a browser. You should see all
4 samples listed in the FastQC section.

---

### Step 6 — Intermediate exercise (ext.args + conf/modules.config)

Complete `exercises/02_intermediate/` — wire FASTQC → MULTIQC and configure
both via a modules.config file.

```bash
nextflow run exercises/02_intermediate/main.nf \
    -profile docker \
    -c exercises/02_intermediate/modules.config \
    --outdir results_intermediate
```

Key learning: the MultiQC report title should change based on what you put in
`ext.args`. If the title doesn't change, check that your `ext.args` closure
syntax is correct — it must be `{ '--title "My Title"' }`, not `'--title ...'`.

---

### Step 7 — Understand conf/modules.config

Open `conf/modules.config` and read it alongside `main.nf`.

The `withName: 'FASTQC'` selector matches by process name. Note that when modules
are inside subworkflows, the full qualified name is used:
`withName: 'PIPELINE_NAME:SUBWORKFLOW_NAME:FASTQC'`.

For this session's flat pipeline, just the process name is sufficient.

**Experiment:** Change `ext.args` for FASTQC from `{ '--quiet' }` to
`{ '--quiet --noextract' }` and re-run with `-resume`. Does the cache
invalidate? (Answer: yes — changing ext.args changes the command hash.)

---

### Step 8 — Challenge exercise (ext.when + patching)

Complete `exercises/03_challenge/main.nf`. This has two parts:

**Part A** — Use `ext.when` to make FASTQC skippable:

```bash
# Normal run (FastQC runs):
nextflow run exercises/03_challenge/main.nf -profile docker

# Skip FastQC:
nextflow run exercises/03_challenge/main.nf -profile docker --skip_fastqc
```

In the second run, FASTQC should not appear in the task list at all.

**Part B** — Practice the patch workflow:

```bash
# 1. Edit the FASTQC module to add a debug echo line
#    Open modules/nf-core/fastqc/main.nf, find the script: block,
#    and add this line after "def prefix = ...":
#    echo "DEBUG: Running FastQC on sample ${prefix}"

# 2. Lint will now fail:
nf-core modules lint fastqc

# 3. Fix it by patching:
nf-core modules patch fastqc

# 4. Lint passes again:
nf-core modules lint fastqc

# 5. Inspect the diff:
cat modules/nf-core/fastqc/fastqc.diff
```

---

## Debugging tips

**"Module not found" / "No such file"**

The include path must be relative to the `.nf` file containing the include,
not to the pipeline root. If your main.nf is at `exercises/01_basic/main.nf`,
then the module is at `../../modules/nf-core/fastqc/main` (note: no `.nf`
extension in include paths).

**"Expected tuple but got map"**

You're passing the meta map directly instead of wrapping it in a tuple.
Change `ch_reads = ch_reads.map { row -> [id: row.sample] }` to
`ch_reads = ch_reads.map { row -> [ [id: row.sample], [file(row.fastq_1)] ] }`.

**"MULTIQC: wrong number of inputs"**

MULTIQC takes exactly 6 arguments. If you call it with fewer, Nextflow will
error. Pass `[]` for any optional inputs you don't need:
`MULTIQC(ch_files, [], [], [], [], [])`.

**"Channel queue is empty" before MULTIQC**

You forgot `.collect()`. Without it, the queue channel is consumed by the
first check and appears empty. Add `.collect()` after stripping the meta.

**ext.args closure not taking effect**

Make sure the value is a closure: `{ '--quiet' }` not `'--quiet'`. Plain
strings are evaluated at config parse time and don't always bind correctly.
Also verify the `withName:` selector matches the exact process name (case-sensitive).

**nf-core lint: "Local copy does not match remote"**

You edited an installed module. Run `nf-core modules patch <tool>` to generate
a tracked diff, then lint will pass.

---

## Key takeaways

nf-core modules are directory bundles (main.nf, meta.yml, environment.yml, tests/)
installed by `nf-core modules install <tool>` and tracked by `modules.json` for
reproducibility. Modules follow one of two input patterns: per-sample tuples
containing a meta map (e.g., FASTQC), or plain aggregation paths with no meta
(e.g., MULTIQC). Module behaviour is configured entirely via `ext.args` closures
in `conf/modules.config`, never by editing module source — this keeps modules
updatable and lint-clean, with `nf-core modules patch` available for the rare
cases where source edits are unavoidable.

---

## 2026 syntax notes

All code in this session already follows 2026 conventions:
- `channel.fromPath()` (lowercase) — not `Channel.fromPath()`
- Explicit closure parameters: `{ meta, zips -> zips }` — not `{ it[1] }`
- No `shell:` blocks — `script:` with `\\` escaping throughout
- No `addParams` in include statements — removed in DSL2

**Topic channels (preview):** The version collection pattern used here
(`ch_versions = FASTQC.out.versions.first()`) is the current standard.
In Session 16 you will learn the 2026 replacement: topic channels, where
modules emit versions via `topic: versions` and no manual `.mix()` wiring
is needed at all. As of nf-core/tools 3.5.0 this pattern is available; it
becomes mandatory Q2 2026.

---

## Reference: nf-core modules CLI quick reference

```bash
# Discovery
nf-core modules list remote                    # all available modules
nf-core modules list remote | grep -i <tool>   # filter
nf-core modules info <tool>                    # detailed info + install command

# Installation
nf-core modules install <tool>                 # install latest
nf-core modules install <tool/subtool>         # tool with subcommand
nf-core modules install --sha <commit> <tool>  # pin to specific commit

# Maintenance
nf-core modules list local                     # what's installed in this pipeline
nf-core modules update <tool>                  # update to latest
nf-core modules update --all                   # update everything
nf-core modules lint <tool>                    # check compliance
nf-core modules patch <tool>                   # track local edits

# After updating — check what changed:
nf-core modules update --preview <tool>        # show diff without applying
nf-core modules update --save-diff diff.patch <tool>  # save diff, apply manually later
```

---

## What's next

**Session 16** — Creating nf-core modules: you'll build a custom module from
scratch using `nf-core modules create`, write the `meta.yml` and `environment.yml`,
implement the 2026 topic channel version pattern, and write nf-test tests.
