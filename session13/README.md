# Session 13 — Introduction to nf-core: Running Community Pipelines

**Source material:** Hello nf-core Part 1 + nf-core Customization  
**Prerequisites:** Sessions 1–12 completed; nf-core conda environment active; Docker (or Singularity) available  
**Estimated time:** 90–120 minutes

---

## Learning Objectives

By the end of this session you will be able to:

- Explain what nf-core is and how its ecosystem is organized (pipelines, modules, subworkflows)
- Discover and explore available community pipelines using `nf-core pipelines list`
- Run an nf-core pipeline with the standard test profile using correct command syntax
- Understand the difference between single-dash Nextflow flags and double-dash pipeline parameters
- Use `nf-core pipelines launch` to configure a run interactively and generate a params file
- Pin pipeline versions for reproducible execution using the `-r` flag
- Download a pipeline for offline use with `nf-core pipelines download`
- Identify the key files and directories in a downloaded nf-core pipeline

---

## Prerequisites Checklist

Before starting, verify the following:

```bash
# Activate the nf-core conda environment
conda activate nf-core

# Confirm Nextflow version (must be >= 25.10.2 for nf-core/demo v1.1.0)
nextflow -v

# Confirm nf-core tools are installed
nf-core --version

# Confirm Docker is running (or substitute singularity below)
docker info | grep "Server Version"
```

Expected output examples:
```
nextflow version 25.04.6
nf-core, version 3.5.2
Server Version: 24.x.x
```

> **Note on Nextflow version:** The nf-core/demo v1.1.0 pipeline requires Nextflow >= 25.10.2.
> If your base environment has an older version, set `NXF_VER` to override:
>
> ```bash
> export NXF_VER=25.10.2
> ```
>
> Add this to your shell profile if needed.

---

## Concepts

### What is nf-core?

**nf-core** is a community-driven project that provides a curated collection of Nextflow pipelines for bioinformatics. It is not a product or company — it is an open-source community with shared standards. As of early 2026 the ecosystem contains over 100 production-grade pipelines, 1,300+ reusable modules, and hundreds of subworkflows, all maintained to consistent quality standards.

Every nf-core pipeline follows the same conventions: a standardized directory layout, parameter validation via `nextflow_schema.json`, a `test` profile with tiny publicly hosted data, container support for Docker/Singularity/Conda, software version reporting, and CI/CD testing on every commit. This means that once you learn how to run one nf-core pipeline, you already know how to run all of them.

### The nf-core tools CLI

The `nf-core` command-line tool (installed via `pip install nf-core`) is a companion utility for both users and developers. For users, its most important subcommands are under `nf-core pipelines`:

| Command | Purpose |
|---|---|
| `nf-core pipelines list` | Browse all available pipelines |
| `nf-core pipelines launch` | Interactive TUI wizard to configure parameters |
| `nf-core pipelines download` | Download pipeline + containers for offline use |
| `nf-core pipelines create-params-file` | Generate a skeleton params YAML file |

> **2026 note:** Since nf-core tools 3.0.0 (October 2024), all pipeline commands require the
> `pipelines` subgroup. The old `nf-core list` shorthand is gone. Always write the full
> `nf-core pipelines <subcommand>` form.

### The `-profile` flag and why it matters

nf-core pipelines define named **profiles** in `nextflow.config` that activate groups of settings.
Two categories of profile are critical to understand:

**Container profiles** tell Nextflow which software environment to use:
- `-profile docker` — use Docker containers
- `-profile singularity` — use Singularity/Apptainer containers
- `-profile conda` — use Conda environments

**Data profiles** set the input parameters for a run:
- `-profile test` — uses a tiny public test dataset; lets you verify the pipeline works
- `-profile test_full` — uses a larger, more realistic dataset (available in some pipelines)

You almost always combine both types: `-profile docker,test`

> **Critical syntax rule:** Profile flags use a **single hyphen**: `-profile`  
> Pipeline parameters use a **double hyphen**: `--outdir`, `--input`  
>
> Writing `--profile docker,test` (double hyphen) will NOT activate any profiles.
> Nextflow will silently treat it as a pipeline parameter called `profile` and ignore it.
> This is the single most common beginner mistake with nf-core.

### Single vs double hyphen: the complete picture

| Flag | Hyphen | Handled by | Example |
|---|---|---|---|
| `-profile` | Single | Nextflow engine | `-profile docker,test` |
| `-r` | Single | Nextflow engine | `-r 1.1.0` |
| `-resume` | Single | Nextflow engine | `-resume` |
| `-params-file` | Single | Nextflow engine | `-params-file nf-params.json` |
| `--input` | Double | Pipeline param | `--input samplesheet.csv` |
| `--outdir` | Double | Pipeline param | `--outdir results` |
| `--max_cpus` | Double | Pipeline param | `--max_cpus 4` |

---

## Exercises

Work through these in order. Each builds on the previous.

---

### Exercise 1 — Basic: Discover pipelines and run the test profile

**Step 1: Create your working directory**

```bash
cd ~/projects/nextflow-training
mkdir session13
cd session13
```

**Step 2: List available nf-core pipelines**

```bash
nf-core pipelines list
```

This prints a table with all available pipelines, their latest versions, star counts, and
when they were last pulled locally. Take a moment to scroll through it.

Now filter to see only pipelines related to quality control:

```bash
nf-core pipelines list qc
```

And sort by most recently released:

```bash
nf-core pipelines list --sort release
```

**Step 3: Look at the nf-core/demo pipeline page**

Visit https://nf-co.re/demo in your browser. This is the standard documentation page every
nf-core pipeline has. Note the sections: Introduction, Usage, Parameters, Output, and Changelog.
Every nf-core pipeline follows this same documentation structure.

nf-core/demo is a deliberately simple pipeline purpose-built for training. It runs three steps:

```
FASTQC → SEQTK_TRIM → MULTIQC
```

It takes a samplesheet CSV as input and produces QC reports. No reference genome required.

**Step 4: Run the pipeline with the test profile**

```bash
nextflow run nf-core/demo \
    -r 1.1.0 \
    -profile docker,test \
    --outdir results_test
```

> **What is happening here?**
> - `nf-core/demo` — Nextflow pulls this from GitHub (github.com/nf-core/demo)
>   and caches it locally in `~/.nextflow/assets/nf-core/demo/`
> - `-r 1.1.0` — pin to this exact release for reproducibility
> - `-profile docker,test` — activate Docker containers AND the built-in test data
> - `--outdir results_test` — where to write final results

Watch the output as it runs. You should see something like:

```
N E X T F L O W  ~  version 25.xx.x

Launching `https://github.com/nf-core/demo` [fervent_tesla] DSL2 - revision: abc123 [1.1.0]


------------------------------------------------------
                                        ,--./,-.
        ___     __   __   __   ___     /,-._.--~'
  |\ | |__  __ /  ` /  \ |__) |__         }  {
  | \| |       \__, \__/ |  \ |___     \`-._,-`-,
                                        `._,._,'
  nf-core/demo v1.1.0
------------------------------------------------------

executor >  local (5)
[xx/xxxxxx] NFCORE_DEMO:DEMO:FASTQC (SAMPLE1_PE)       | 3 of 3 ✔
[xx/xxxxxx] NFCORE_DEMO:DEMO:SEQTK_TRIM (SAMPLE1_PE)   | 3 of 3 ✔
[xx/xxxxxx] NFCORE_DEMO:DEMO:MULTIQC                    | 1 of 1 ✔
-[nf-core/demo] Pipeline completed successfully -
```

**Step 5: Examine the outputs**

```bash
ls -la results_test/
```

You should see:
```
results_test/
├── fastqc/          ← FastQC HTML reports (one per sample)
├── fq/              ← Trimmed FASTQ files from seqtk
├── multiqc/         ← Aggregated QC report
└── pipeline_info/   ← Execution reports, trace, DAG, params JSON
```

Open the MultiQC report:
```bash
ls results_test/multiqc/
# Find the HTML file and open it in a browser
```

Also look at the pipeline_info directory:
```bash
ls results_test/pipeline_info/
# You'll see: execution_report.html, execution_trace.txt,
# execution_timeline.html, pipeline_dag.html, nf_core_demo_software_mqc_versions.yml
```

**Step 6: Examine the cached pipeline code**

```bash
ls ~/.nextflow/assets/nf-core/demo/
```

This is the full pipeline source code. Browse through it:

```bash
# The entry point
cat ~/.nextflow/assets/nf-core/demo/main.nf

# The config where profiles are defined
cat ~/.nextflow/assets/nf-core/demo/nextflow.config

# The test data config
cat ~/.nextflow/assets/nf-core/demo/conf/test.config

# See how modules are organized
ls ~/.nextflow/assets/nf-core/demo/modules/nf-core/
```

> **What to notice in `conf/test.config`:**
> The test profile sets `params.input` to a URL on GitHub, and caps resources.
> Notice it does NOT set `params.outdir` — that's why you must always provide `--outdir`.

---

### Exercise 2 — Intermediate: Use `nf-core pipelines launch` and run with a params file

The `nf-core pipelines launch` command reads the pipeline's parameter schema and walks you
through configuration step by step. This is especially useful for complex pipelines with
many parameters.

**Step 1: Launch the interactive wizard**

```bash
nf-core pipelines launch nf-core/demo -r 1.1.0
```

The wizard will ask you questions in groups. For this exercise:
- When asked for `input`, provide: `sample_data/samplesheet.csv`
  (we will create this file in Step 3)
- When asked for `outdir`, provide: `results_custom`
- Leave all other parameters at their defaults
- At the end, choose to save the params file as `nf-params.json`

**Step 2: Examine the generated params file**

```bash
cat nf-params.json
```

It should look like:
```json
{
    "input": "sample_data/samplesheet.csv",
    "outdir": "results_custom"
}
```

This JSON file captures only the parameters you changed from their defaults — the rest are
handled by the pipeline itself. You can edit this file directly and re-use it for future runs.

**Step 3: Create the sample data directory and samplesheet**

The `sample_data/` directory and a samplesheet are included in this session's materials.
Copy them to your working directory:

```bash
cp -r ~/projects/nextflow-training/session13_materials/sample_data ./sample_data
```

Or if running from the extracted tar.gz, the `sample_data/` directory is already present.

Look at the samplesheet:

```bash
cat sample_data/samplesheet.csv
```

You'll see:
```csv
sample,fastq_1,fastq_2
CONTROL_REP1,sample_data/reads/CONTROL_REP1_1.fastq.gz,sample_data/reads/CONTROL_REP1_2.fastq.gz
CONTROL_REP2,sample_data/reads/CONTROL_REP2_1.fastq.gz,sample_data/reads/CONTROL_REP2_2.fastq.gz
TREATMENT_REP1,sample_data/reads/TREATMENT_REP1_1.fastq.gz,sample_data/reads/TREATMENT_REP1_2.fastq.gz
```

> **About the samplesheet format:**
> - `sample` — a unique identifier for each sample
> - `fastq_1` — path to read 1 (required)
> - `fastq_2` — path to read 2 (leave empty for single-end data)
> - Rows with the same `sample` name are automatically concatenated by the pipeline

**Step 4: Run with the params file**

```bash
nextflow run nf-core/demo \
    -r 1.1.0 \
    -profile docker \
    -params-file nf-params.json
```

> **Note:** We no longer need `-profile test` here because our params file already
> specifies `input` and `outdir`. We keep `-profile docker` for the container engine.

Watch the output. It should process your three samples.

**Step 5: Experiment with resource capping**

If you're on a laptop or resource-constrained machine, you can cap resource usage:

```bash
nextflow run nf-core/demo \
    -r 1.1.0 \
    -profile docker \
    -params-file nf-params.json \
    --max_cpus 2 \
    --max_memory 4.GB \
    --outdir results_capped
```

`--max_cpus`, `--max_memory`, and `--max_time` are standard parameters available in all
nf-core pipelines. They do not override individual process requests — instead they act as
a ceiling.

---

### Exercise 3 — Challenge: Download for offline use and explore the directory structure

In real-world bioinformatics, you often need to run pipelines on HPC clusters without
internet access. `nf-core pipelines download` packages everything needed.

**Step 1: Create a params file for `create-params-file`**

First, generate a skeleton params YAML to see all available parameters:

```bash
nf-core pipelines create-params-file nf-core/demo -r 1.1.0 -o demo_params_skeleton.yml
cat demo_params_skeleton.yml
```

This shows every configurable parameter with its default value and description as comments.
It is the fastest way to discover what a pipeline can do.

**Step 2: Download the pipeline for offline use**

```bash
nf-core pipelines download nf-core/demo \
    --revision 1.1.0 \
    --container-system singularity \
    --compress none \
    --outdir nf-core-demo-offline
```

> If you don't have Singularity available, use `--container-system docker` instead,
> or `--container-system none` to download only the code (no containers).

This will:
1. Clone the pipeline code to `nf-core-demo-offline/workflow/`
2. Download container images to `nf-core-demo-offline/singularity-containers/`
3. Download institutional configs to `nf-core-demo-offline/configs/`
4. Patch `nextflow.config` to reference local config files

**Step 3: Explore the downloaded directory**

```bash
# Overall structure
ls -la nf-core-demo-offline/

# The full pipeline code
ls nf-core-demo-offline/workflow/

# The individual nf-core modules
ls nf-core-demo-offline/workflow/modules/nf-core/

# The main workflow (this is where the pipeline logic lives)
cat nf-core-demo-offline/workflow/workflows/demo.nf

# The modules config (this is where ext.args would be set)
cat nf-core-demo-offline/workflow/conf/modules.config
```

**Step 4: Run the offline pipeline**

```bash
nextflow run nf-core-demo-offline/workflow/ \
    -profile docker,test \
    --outdir results_offline
```

Note the path: `nf-core-demo-offline/workflow/` instead of `nf-core/demo`. This runs
from local files — no internet needed.

**Step 5: Examine the modules.config and understand ext.args**

Open `nf-core-demo-offline/workflow/conf/modules.config`:

```bash
cat nf-core-demo-offline/workflow/conf/modules.config
```

You will see entries like:

```groovy
process {
    withName: 'NFCORE_DEMO:DEMO:FASTQC' {
        ext.args = '--quiet'
    }
}
```

This is how nf-core passes additional tool arguments without modifying module code.
The `ext.args` pattern is one of the most important nf-core conventions you will use
as a developer (covered in detail in Sessions 14–16).

**Step 6: Add a custom argument via your own config file**

Create a file called `my_custom.config` in your session13 working directory:

```groovy
// my_custom.config
// Custom configuration for nf-core/demo
// Demonstrates how to override ext.args for a specific process

process {
    withName: 'NFCORE_DEMO:DEMO:FASTQC' {
        // Pass additional FastQC flags
        // --quiet suppresses progress messages in stdout
        // --threads 2 allows FastQC to use 2 threads internally
        ext.args = '--quiet --threads 2'
    }
}
```

Then run with your custom config using `-c`:

```bash
nextflow run nf-core/demo \
    -r 1.1.0 \
    -profile docker,test \
    -c my_custom.config \
    --outdir results_with_custom_config
```

Compare the execution trace with and without your custom config. The outputs should
be identical — you've only modified internal FastQC options that don't affect the
QC report content.

---

## Key Concepts Reference Card

### The anatomy of a run command

```
nextflow run  nf-core/demo    -r 1.1.0      -profile docker,test    --outdir results
│             │               │              │                        │
│             │               │              │                        └── pipeline param (double --)
│             │               │              └── Nextflow flag (single -)
│             │               └── version pin (single -)
│             └── pipeline name (GitHub repo)
└── Nextflow executable
```

### The samplesheet format

```csv
sample,fastq_1,fastq_2
SAMPLE_PE,reads/sample_R1.fastq.gz,reads/sample_R2.fastq.gz  ← paired-end
SAMPLE_SE,reads/sample_R1.fastq.gz,                           ← single-end (empty fastq_2)
SAMPLE_MERGE,reads/lane1_R1.fastq.gz,reads/lane1_R2.fastq.gz ← these two rows
SAMPLE_MERGE,reads/lane2_R1.fastq.gz,reads/lane2_R2.fastq.gz ← get merged
```

### Pipeline output structure

```
results/
├── fastqc/          ← tool-specific outputs
├── fq/              ← tool-specific outputs  
├── multiqc/         ← aggregated QC report
└── pipeline_info/   ← execution metadata (always present in nf-core pipelines)
    ├── execution_report.html    ← interactive HTML with task details
    ├── execution_trace.txt      ← tab-separated task performance data
    ├── execution_timeline.html  ← Gantt-style timeline
    └── pipeline_dag.html        ← rendered DAG (requires Graphviz or browser)
```

### Resource override params (available in all nf-core pipelines)

```bash
--max_cpus 4        # Cap total CPUs per task
--max_memory 8.GB   # Cap memory per task
--max_time 1.h      # Cap wall-time per task
```

---

## Debugging Tips

**Problem:** Pipeline starts but immediately errors: `command not found: fastqc`  
**Cause:** No container profile specified, or Docker daemon is not running  
**Fix:** Add `-profile docker` (or `singularity`) to your command; verify Docker with `docker info`

---

**Problem:** Pipeline appears to run but produces no output  
**Cause:** You used `--profile` (double hyphen) instead of `-profile` (single hyphen)  
**Fix:** Use single hyphen: `-profile docker,test` — double hyphen means pipeline parameter

---

**Problem:** `WARN: Nextflow version does not match pipeline requirements`  
**Cause:** Your Nextflow version is older than the pipeline's `manifest.nextflowVersion`  
**Fix:** `export NXF_VER=25.10.2` then re-run, or update Nextflow: `nextflow self-update`

---

**Problem:** `--outdir` is required but not provided  
**Cause:** The `test` profile does NOT set `outdir` — you must always provide it  
**Fix:** Always include `--outdir <path>` in your command

---

**Problem:** `nf-core list` gives `Error: No such command 'list'`  
**Cause:** You are using nf-core tools 3.0.0+ where the command structure changed  
**Fix:** Use `nf-core pipelines list` (with the `pipelines` subgroup)

---

**Problem:** Pipeline ran with `-profile test` but no input files appear in results  
**Cause:** Test profile uses remote data from GitHub — check internet connectivity  
**Fix:** Verify you can curl the test samplesheet URL:
```bash
curl -L https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv
```

---

## Key Takeaways

nf-core provides over 100 production-grade bioinformatics pipelines that all share the same conventions: run any of them with `nextflow run nf-core/<name> -r <version> -profile docker,test --outdir results` and they will work out of the box. The single most important syntax detail is the single-hyphen vs double-hyphen distinction — `-profile` and `-r` are Nextflow engine flags while `--input` and `--outdir` are pipeline parameters. The `nf-core pipelines` subcommands (list, launch, download, create-params-file) cover the full lifecycle of using community pipelines, from discovery through offline deployment. In the next session you will look inside the pipeline code and understand how every file in the nf-core template connects together.

---

## Further Reading

- nf-core/demo documentation: https://nf-co.re/demo
- nf-core getting started: https://nf-co.re/docs/usage/getting_started/introduction
- nf-core tools CLI docs: https://nf-co.re/docs/nf-core-tools/pipelines/list
- training.nextflow.io Hello nf-core Part 1: https://training.nextflow.io/hello_nf-core/01_run_demo/
