# Session 14 — nf-core Pipeline Structure: Anatomy of a Template Pipeline

## Learning objectives

By the end of this session you will be able to:

- Describe every directory and file produced by `nf-core pipelines create` and explain its role
- Read and understand the three-layer delegation pattern: unnamed entry workflow → named wrapper → pipeline workflow
- Explain the `take:` / `main:` / `emit:` composable workflow pattern and why it exists
- Add a custom local process to an nf-core template pipeline and wire it into the main workflow
- Configure per-process arguments and publishing using `conf/modules.config` with `ext.args` and `ext.prefix`
- Convert a plain Nextflow pipeline into the nf-core template structure

---

## Prerequisites

- Sessions 1–13 complete
- nf-core tools installed in your nf-core conda environment:
  ```bash
  conda activate nf-core
  nf-core --version    # should be 3.4.0 or higher
  ```
- Nextflow 25.04+ available:
  ```bash
  nextflow -version
  ```
- The Session 3 pipeline files (SAY_HELLO → CONVERT_UPPER → COLLECT_RESULTS) — these are also
  provided in `exercise3_nfcore_conversion/` as a starting reference

---

## Background concepts

### Why does the template exist?

When a pipeline follows the nf-core template, it gains several things for free: automatic parameter
validation (via the nf-schema plugin), standardised resource labelling, container support across Docker /
Singularity / Conda, CI/CD configuration, and a lint tool that checks for compliance. The trade-off is
structural complexity up front. This session is about understanding that structure so it does not feel
overwhelming.

### The three-layer delegation chain

An nf-core pipeline has three nested workflow scopes:

```
nextflow run main.nf
    └── workflow {}          ← unnamed entry point (in main.nf)
            └── NFCORE_MYPIPELINE   ← named wrapper (in main.nf)
                    └── MYPIPELINE  ← core logic (in workflows/mypipeline.nf)
```

Each layer has a specific job:
- The **unnamed workflow** handles initialisation (samplesheet parsing, param validation) and
  completion (email, reports).
- The **named wrapper** `NFCORE_MYPIPELINE` exists so that the pipeline can be imported and called
  from another pipeline — it is the "public API" of the pipeline.
- The **MYPIPELINE workflow** in `workflows/` is where all the actual processes are called.

### conf/modules.config — the "control panel"

Process arguments are **never** hardcoded inside module files. Instead, every module reads
`task.ext.args` and `task.ext.prefix` at runtime, and those values are set inside
`conf/modules.config` using `withName` selectors. This separation means you can change a tool's
arguments in one config file without touching the module code.

```
modules.config sets:      process.ext.args = '--quiet'
                                    ↓
module script reads:      def args = task.ext.args ?: ''
                                    ↓
bash command becomes:     fastqc --quiet sample.fastq.gz
```

### 2026 notes (things to be aware of)

- All examples in this session use **lowercase `channel.of()`** — the uppercase `Channel.of()` form
  still works but is deprecated and banned under the strict v2 parser.
- All closures use **explicit parameters** (`{ meta, reads -> ... }` not `{ it -> ... }`).
- The template now uses **topic channels** for version collection (tools 3.5.0+). The old
  `versions.yml` pattern still works but will be replaced. Session 16 covers topic channels in detail.
- `publishDir` in processes is the current pattern in the template. The newer **workflow output:**
  block (stable in Nextflow 25.10) will eventually replace it. Session 19 covers that transition.

---

## Exercise 1 — Explore an nf-core template pipeline

**Goal:** Create a pipeline from the nf-core template, examine every file, and identify the entry point.

### Step 1 — Activate the nf-core environment

```bash
conda activate nf-core
cd ~/projects/nextflow-training
mkdir session14 && cd session14
```

### Step 2 — Create a pipeline

Run the interactive TUI:

```bash
nf-core pipelines create
```

You will be prompted for:
- **Pipeline name:** `greetings`
- **Description:** `A training pipeline that generates and transforms greetings`
- **Author:** your name
- **Version:** `1.0.0dev`

When asked about template features, you can accept the defaults. A directory called
`nf-core-greetings/` will be created.

**What just happened?** nf-core tools generated ~50 files based on the template in
`nf_core/pipeline-template/`. You did not write any of this. Now you are going to read it.

### Step 3 — Map the directory tree

```bash
cd nf-core-greetings
find . -not -path './.git/*' -not -path './node_modules/*' | sort | head -80
```

Use the annotated tree below to identify each directory:

```
nf-core-greetings/
├── main.nf                        ← ENTRY POINT — read this first
├── nextflow.config                ← top-level config, includes conf/*
├── nextflow_schema.json           ← parameter schema for nf-schema validation
├── modules.json                   ← tracks installed nf-core module versions
├── .nf-core.yml                   ← template feature flags and lint exceptions
│
├── workflows/
│   └── greetings.nf               ← core workflow with take:/main:/emit:
│
├── modules/
│   ├── local/                     ← your custom processes go here
│   └── nf-core/                   ← community modules installed by nf-core tools
│
├── subworkflows/
│   ├── local/
│   │   └── utils_nfcore_greetings_pipeline/main.nf  ← init + completion logic
│   └── nf-core/
│       ├── utils_nfcore_pipeline/  ← version collation helpers
│       └── utils_nextflow_pipeline/ ← Nextflow version checks
│
├── conf/
│   ├── base.config                ← resource labels (process_single → process_high)
│   ├── modules.config             ← per-process ext.args and publishDir
│   ├── test.config                ← minimal test profile
│   └── test_full.config           ← full-size test profile
│
├── assets/
│   ├── schema_input.json          ← samplesheet schema (columns, types, required)
│   ├── multiqc_config.yml
│   └── email_template.html
│
└── docs/
    ├── usage.md
    └── output.md
```

### Step 4 — Read main.nf

Open `main.nf`. You should see:

```bash
cat main.nf
```

Look for:
1. The `include` statements at the top — what is being imported?
2. A **named workflow** `NFCORE_GREETINGS` — what does it take as input and emit?
3. The **unnamed `workflow {}`** block at the bottom — this is what Nextflow actually runs.

**Question:** Can you trace the path from the unnamed workflow down to where `PIPELINE_INITIALISATION`
is called, and what it returns?

### Step 5 — Read workflows/greetings.nf

```bash
cat workflows/greetings.nf
```

This is mostly a skeleton with placeholder comments. Notice:
- The `take:` block — declares the input channel
- The `main:` block — this is where you will add process calls
- The `emit:` block — exposes outputs to the caller

### Step 6 — Read conf/base.config

```bash
cat conf/base.config
```

Notice the `withLabel` selectors: `process_single`, `process_low`, `process_medium`, `process_high`,
`process_long`, `process_high_memory`. Every nf-core module uses one of these labels. Your processes
should too.

### Step 7 — Read conf/modules.config

```bash
cat conf/modules.config
```

This file may be nearly empty in a fresh template. This is where you will add `withName` blocks in
Exercise 2.

**Expected outcome:** You can answer the question "what does main.nf actually do?" without looking
anything up.

---

## Exercise 2 — Add a local process to the template

**Goal:** Add a custom `SAY_HELLO` process as a local module, wire it into the main workflow,
and configure it via `conf/modules.config`.

The files in `exercise2_add_process/` show the completed state. Work through the steps below in your
`nf-core-greetings/` directory.

### Step 1 — Create the local module

Create the file `modules/local/say_hello/main.nf` with the following content:

```groovy
/*
 * Local module: SAY_HELLO
 * Writes a greeting to a text file.
 * This is a teaching module — in a real pipeline this would be a
 * bioinformatics tool like FASTQC or TRIMGALORE.
 */
process SAY_HELLO {

    tag "$meta.id"
    label 'process_single'

    // No container needed for a pure bash process.
    // Real nf-core modules always have a container directive.

    input:
    tuple val(meta), val(greeting)

    output:
    tuple val(meta), path("${prefix}.txt"), emit: txt
    path  "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Read ext.args and ext.prefix from modules.config (or use defaults)
    def args   = task.ext.args   ?: ''
    prefix     = task.ext.prefix ?: "${meta.id}"
    """
    echo "${greeting} from ${meta.id} ${args}" > ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
```

**Why is `prefix` declared without `def`?**
Because it is used in the `output:` block via `${prefix}.txt`. Variables declared with `def` are
local to the `script:` block and cannot be referenced in `output:`. Variables without `def` are
visible to the output block.

**Note on `val` vs `path` for the greeting input:**
We are using `val(greeting)` here because the greeting is a plain string value, not a file path. In
a real bioinformatics pipeline, this input would typically be `path(reads)` — a path to a FASTQ
file. The pattern is otherwise identical.

### Step 2 — Import and call the process in workflows/greetings.nf

Edit `workflows/greetings.nf`. Add the include at the top and the process call in the main block:

```groovy
include { SAY_HELLO } from '../modules/local/say_hello/main'
```

Inside the `main:` block:

```groovy
main:
ch_versions = channel.empty()

//
// MODULE: SAY_HELLO
//
SAY_HELLO ( ch_samplesheet )

ch_versions = ch_versions.mix(SAY_HELLO.out.versions.first())

emit:
versions = ch_versions
```

### Step 3 — Configure in conf/modules.config

Add a `withName` block for `SAY_HELLO`:

```groovy
process {
    withName: 'SAY_HELLO' {
        ext.args   = '(nf-core training)'
        publishDir = [
            path: { "${params.outdir}/greetings" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
    }
}
```

**What does `saveAs` do?** It filters the list of files being published. The expression
`filename.equals('versions.yml') ? null : filename` means: if the file is `versions.yml`, return
`null` (do not publish it); otherwise publish it normally. This keeps `versions.yml` files out of
your results directory.

### Step 4 — Create a minimal samplesheet

Create `assets/samplesheet.csv`:

```csv
sample,greeting
sample1,Hello
sample2,Bonjour
sample3,Holà
```

### Step 5 — Update assets/schema_input.json

The schema tells nf-schema what columns are valid in the samplesheet. Replace the contents of
`assets/schema_input.json` with the file provided in `exercise2_add_process/assets/schema_input.json`.

### Step 6 — Run the pipeline

```bash
nextflow run main.nf \
    --input assets/samplesheet.csv \
    --outdir results \
    -profile docker
```

If you do not have Docker available, omit `-profile docker` for local execution (since the SAY_HELLO
process is pure bash, no container is needed).

**Expected output:**

```
N E X T F L O W  ~  version 25.x.x
Launching `main.nf` [friendly_name] DSL2 - revision: ...

executor >  local (3)
[xx/xxxxxx] SAY_HELLO (sample1) [100%] 3 of 3 ✔

results/
└── greetings/
    ├── sample1.txt    → "Hello from sample1 (nf-core training)"
    ├── sample2.txt    → "Bonjour from sample2 (nf-core training)"
    └── sample3.txt    → "Holà from sample3 (nf-core training)"
```

**Notice:** The `(nf-core training)` suffix came from `ext.args` in `modules.config`, NOT from the
process itself. The process just reads `$args` and appends it. This is the key insight: the process
is generic; the config makes it specific.

### Intermediate exercise — Change ext.args without touching the module

In `conf/modules.config`, change:

```groovy
ext.args = '(nf-core training)'
```

to:

```groovy
ext.args = { "(session14 run at ${new Date().format('yyyy-MM-dd')})" }
```

Re-run with `-resume`. Does the process re-execute? Yes — because `ext.args` changed, which changes
the command hash, which invalidates the cache. This is expected and correct behaviour.

### Challenge exercise — Add a second process and chain them

Add a second local module at `modules/local/convert_upper/main.nf` that uppercases the greeting file
(use `tr '[:lower:]' '[:upper:]'`). Chain it after `SAY_HELLO` in `workflows/greetings.nf`. Configure
it in `conf/modules.config` with a different `publishDir` path.

---

## Exercise 3 — Convert the Session 3 pipeline to nf-core template format

**Goal:** Take the three-process pipeline (SAY_HELLO → CONVERT_UPPER → COLLECT_RESULTS) and
restructure it so that it follows the nf-core template layout exactly.

The completed files are in `exercise3_nfcore_conversion/`. Study the diff between the original
Session 3 pipeline and the converted version.

### The key structural changes

| Session 3 pattern | nf-core template pattern |
|---|---|
| All processes in `main.nf` | Processes in `modules/local/<name>/main.nf` |
| Workflow logic in `main.nf` | Workflow logic in `workflows/greetings.nf` |
| Parameters defined inline | Parameters in `nextflow.config` `params {}` block |
| No publishing config | `publishDir` set in `conf/modules.config` |
| No resource labels | `label 'process_single'` on every process |
| No `versions.yml` | Every process outputs `versions.yml` |
| No `ext.args` | Every process reads `task.ext.args ?: ''` |
| No `stub:` block | Every process has a `stub:` block |

### Step 1 — Examine the local module files

Open `exercise3_nfcore_conversion/modules/local/say_hello/main.nf`. Compare it to the original
Session 3 process. Notice:

- `tag "$meta.id"` — identifies which sample is running in the log
- `label 'process_single'` — maps to resource limits in `conf/base.config`
- `when: task.ext.when == null || task.ext.when` — allows conditional skipping via config
- `def args = task.ext.args ?: ''` and `prefix = task.ext.prefix ?: "${meta.id}"` — the
  config injection points
- The `stub:` block — creates empty output files for dry-run testing
- `versions.yml` output — even a bash `echo` command reports a version

### Step 2 — Examine the main workflow

Open `exercise3_nfcore_conversion/workflows/greetings.nf`. Notice:

- `take: ch_samplesheet` — the samplesheet channel comes from `PIPELINE_INITIALISATION`, not from
  `channel.fromPath()` directly in the workflow
- Each process call is wrapped in a comment block: `// MODULE: PROCESS_NAME //`
- `ch_versions` starts as `channel.empty()` and grows by mixing in each process's versions output
- `emit:` exposes `multiqc_report` and `versions` — even if they are empty channels, the interface
  is always declared

### Step 3 — Examine conf/modules.config

Open `exercise3_nfcore_conversion/conf/modules.config`. Notice how each process gets its own
`withName` block with a `publishDir` that places outputs in a subdirectory of `params.outdir`, and
how `ext.args` provides the default empty string that the process will consume.

### Step 4 — Run the converted pipeline

```bash
cd exercise3_nfcore_conversion
nextflow run main.nf \
    --input assets/samplesheet.csv \
    --outdir results \
    --publish_dir_mode copy
```

The output structure should be:

```
results/
├── greetings/
│   ├── sample1.txt
│   ├── sample2.txt
│   └── sample3.txt
├── upper/
│   ├── SAMPLE1.txt
│   ├── SAMPLE2.txt
│   └── SAMPLE3.txt
├── collected/
│   └── all_greetings.txt
└── pipeline_info/
    ├── pipeline_report.html
    ├── pipeline_report.txt
    └── software_versions.yml
```

---

## Debugging tips

**1. "No such variable: meta" inside a process script**

You likely have `val(meta)` in the input but are trying to use `${meta.id}` before the `def`
declarations. Make sure you extract map values into `def` variables before the triple-quoted block
if you are using heredocs:

```groovy
script:
def sample_id = meta.id   // extract before triple-quote
prefix = task.ext.prefix ?: "${sample_id}"
"""
echo $sample_id
"""
```

**2. withName selector not matching**

The `withName` selector must match the full process name. If the process is called inside a named
workflow, its full name is `NFCORE_GREETINGS:GREETINGS:SAY_HELLO`. The selector `withName: 'SAY_HELLO'`
still works as a partial match (Nextflow matches any path ending in `SAY_HELLO`). Use
`withName: '.*:SAY_HELLO'` if you need to be explicit.

**3. "ext.args not found" or empty args**

If `task.ext.args` is null (no `withName` block set it), the expression `task.ext.args ?: ''`
safely returns an empty string. This is intentional — the module runs without extra arguments.
Only add `ext.args` to `modules.config` when you want to pass something.

**4. publishDir not creating the directory**

`publishDir` does not create parent directories automatically if `params.outdir` is an empty string.
Always pass `--outdir results` (or any non-empty path) when running.

**5. Lint errors about `Channel` vs `channel`**

If `nf-core pipelines lint` reports "use lowercase `channel`", globally replace `Channel.of`,
`Channel.fromPath`, `Channel.empty`, `Channel.value` with their lowercase equivalents. The
`channel.fromList()` factory was introduced in newer Nextflow versions — verify you are on 25.04+.

---

## Key takeaways

The nf-core template enforces a clean separation of concerns: processes live in `modules/`, pipeline
logic lives in `workflows/`, and all configuration — arguments, publishing, resource limits — lives in
`conf/`. The `ext.args` pattern is the single most important idiom to understand because it is what
makes every nf-core module reusable: the module code never changes, only the config does. The
three-layer delegation chain (`unnamed workflow → NFCORE_PIPELINE → PIPELINE`) exists to make the
pipeline importable by other pipelines, and to give init and completion logic a clean place to live.
