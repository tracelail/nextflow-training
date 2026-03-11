# Session 13 — Quick Reference Cheat Sheet

## nf-core tools commands (v3.5.x)

```bash
# List all pipelines
nf-core pipelines list

# Filter by keyword
nf-core pipelines list rnaseq

# Sort by release date
nf-core pipelines list --sort release

# Launch interactive TUI wizard (saves nf-params.json)
nf-core pipelines launch nf-core/demo -r 1.1.0

# Generate skeleton params YAML (all parameters with defaults)
nf-core pipelines create-params-file nf-core/demo -r 1.1.0 -o params.yml

# Download for offline use (code only)
nf-core pipelines download nf-core/demo --revision 1.1.0 --container-system none --outdir ./offline

# Download with Singularity containers
nf-core pipelines download nf-core/demo --revision 1.1.0 --container-system singularity --outdir ./offline
```

---

## Run commands

```bash
# Standard test run (always start here)
nextflow run nf-core/demo -r 1.1.0 -profile docker,test --outdir results

# With params file
nextflow run nf-core/demo -r 1.1.0 -profile docker -params-file nf-params.json

# With custom config
nextflow run nf-core/demo -r 1.1.0 -profile docker,test -c my_custom.config --outdir results

# Resource-capped (for laptops)
nextflow run nf-core/demo -r 1.1.0 -profile docker,test --outdir results --max_cpus 2 --max_memory 4.GB

# Run downloaded offline pipeline
nextflow run ./nf-core-demo-offline/workflow/ -profile docker,test --outdir results

# Override Nextflow version
NXF_VER=25.10.2 nextflow run nf-core/demo -r 1.1.0 -profile docker,test --outdir results
```

---

## Hyphen rules (the #1 source of confusion)

| Flag | Hyphens | Type | Correct example |
|---|---|---|---|
| `-profile` | 1 | Nextflow engine | `-profile docker,test` |
| `-r` | 1 | Nextflow engine | `-r 1.1.0` |
| `-resume` | 1 | Nextflow engine | `-resume` |
| `-c` | 1 | Nextflow engine | `-c my.config` |
| `-params-file` | 1 | Nextflow engine | `-params-file nf-params.json` |
| `--input` | 2 | Pipeline param | `--input samplesheet.csv` |
| `--outdir` | 2 | Pipeline param | `--outdir results` |
| `--max_cpus` | 2 | Pipeline param | `--max_cpus 4` |

**Wrong:** `nextflow run nf-core/demo --profile docker,test`  
**Right:** `nextflow run nf-core/demo -profile docker,test`

---

## Samplesheet format

```csv
sample,fastq_1,fastq_2
SAMPLENAME,/path/to/R1.fastq.gz,/path/to/R2.fastq.gz   ← paired-end
SAMPLENAME,/path/to/R1.fastq.gz,                        ← single-end
```

Rules:
- Header row required with exactly these column names
- `sample` must be unique per biological replicate (duplicates are merged)
- `fastq_2` column required but can be empty for single-end
- Paths can be absolute or relative to the launch directory

---

## Key directories to know

```
~/.nextflow/assets/nf-core/demo/   ← cached pipeline code after first run
work/                               ← Nextflow task work directories
results/
└── pipeline_info/
    ├── execution_report.html       ← interactive task report
    ├── execution_trace.txt         ← per-task performance (TSV)
    ├── execution_timeline.html     ← Gantt chart
    └── pipeline_dag.html           ← DAG visualization
```

---

## Diagnose a failed run

```bash
# Find the work directory hash for a failed task from the error message
# e.g. [ab/1234ef]
ls work/ab/1234ef*/

# Read the command that was run
cat work/ab/1234ef*/.command.sh

# Read the error output
cat work/ab/1234ef*/.command.err

# Read exit code
cat work/ab/1234ef*/.exitcode

# Resume after fixing the issue
nextflow run nf-core/demo -r 1.1.0 -profile docker,test --outdir results -resume
```

---

## nf-core/demo pipeline (v1.1.0) facts

| Property | Value |
|---|---|
| Steps | FASTQC → SEQTK_TRIM → MULTIQC |
| Min Nextflow version | 25.10.2 |
| nf-core tools version used | 3.5.1 |
| Test data | SARS-CoV-2 amplicon (viralrecon branch) |
| Test samples | 3 (SAMPLE1_PE, SAMPLE2_PE, SAMPLE3_SE) |
| Reference genome required | No |
| GPU required | No |
