# Session 15 — Expected Outputs

This document describes what a successful run of each exercise produces.
Use it to verify your pipeline is working correctly.

---

## Running the complete pipeline (main.nf)

```bash
cd /home/trace/projects/nextflow-training/session15

# First, install the modules (only needed once):
nf-core modules install fastqc
nf-core modules install multiqc

# Run with Docker:
nextflow run main.nf -profile docker

# Run with stub mode (no containers needed — great for testing structure):
nextflow run main.nf -stub
```

### Directory tree after a successful run

```
results/
├── fastqc/
│   ├── sample1_fastqc.html
│   ├── sample2_fastqc.html
│   ├── sample3_fastqc.html
│   └── sample4_fastqc.html
├── multiqc/
│   ├── multiqc_data/
│   │   ├── multiqc_fastqc.txt
│   │   ├── multiqc_general_stats.txt
│   │   └── multiqc_sources.txt
│   └── multiqc_report.html
└── pipeline_info/
    ├── execution_report.html
    ├── execution_timeline.html
    └── execution_trace.txt
```

### Console output (key lines to look for)

```
executor >  local (5)
[xx/xxxxxx] FASTQC (sample1) [100%] 4 of 4 ✔
[xx/xxxxxx] MULTIQC          [100%] 1 of 1 ✔

==========================================
 Session 15 pipeline complete!
==========================================
 Status   : SUCCESS
 Results  : results/
 Duration : ~30s (with Docker)
==========================================
```

Key things to verify:
- **4 FASTQC tasks** — one per sample, all running in parallel (shown as `4 of 4`)
- **1 MULTIQC task** — runs after all FASTQC tasks complete
- `results/fastqc/` contains HTML files (one per sample)
- `results/multiqc/multiqc_report.html` exists and shows 4 samples

---

## Stub mode output

Stub mode (`-stub`) runs without containers or real tools. It executes the `stub:`
blocks in each module, creating empty placeholder files.

```bash
nextflow run main.nf -stub
```

Expected output files (empty but present):
```
results/fastqc/
├── sample1.html        ← empty stub file
├── sample2.html
├── sample3.html
└── sample4.html
results/multiqc/
└── multiqc_report.html ← empty stub file
```

This is useful for checking that your channel wiring and module includes are
correct before investing time in a full container-based run.

---

## Exercise 01 — Basic (FASTQC only)

```bash
nextflow run exercises/01_basic/solution.nf -profile docker
```

Expected console output:
```
[xx/xxxxxx] FASTQC (sample1) | 4 of 4 ✔
Sample: sample1 → /path/to/work/.../sample1_fastqc.html
Sample: sample2 → /path/to/work/.../sample2_fastqc.html
Sample: sample3 → /path/to/work/.../sample3_fastqc.html
Sample: sample4 → /path/to/work/.../sample4_fastqc.html
```

Note: The `.view{}` output will be in RANDOM ORDER — Nextflow processes samples
in parallel, and whichever finishes first emits first. This is normal.

---

## Exercise 02 — Intermediate (FASTQC + MULTIQC + modules.config)

```bash
nextflow run exercises/02_intermediate/solution.nf \
    -profile docker \
    -c exercises/02_intermediate/solution_modules.config \
    --outdir results_intermediate
```

Expected:
- 4 FASTQC tasks + 1 MULTIQC task
- `results_intermediate/multiqc/session15_multiqc_report.html` (note the custom prefix)
- The MultiQC report title bar shows "Session 15 QC Report" (from --title flag)

---

## Exercise 03 — Challenge (ext.when skip)

```bash
# Normal run — FastQC executes:
nextflow run exercises/03_challenge/main.nf -profile docker

# Skip run — FastQC does NOT appear in task list:
nextflow run exercises/03_challenge/main.nf -profile docker --skip_fastqc
```

With `--skip_fastqc`, expected console output:
```
executor >  local (1)
[xx/xxxxxx] MULTIQC [100%] 1 of 1 ✔
Pipeline complete (FastQC was skipped). Results in: results
```

FastQC does not appear at all — `ext.when = false` suppresses it entirely.
MultiQC runs but produces a near-empty report (nothing to aggregate).

---

## modules.json — what it should look like after installing both modules

After running `nf-core modules install fastqc` and `nf-core modules install multiqc`,
your `modules.json` should look like this:

```json
{
    "name": "session15",
    "homePage": "https://github.com/your-org/session15",
    "repos": {
        "https://github.com/nf-core/modules.git": {
            "modules": {
                "nf-core": {
                    "fastqc": {
                        "branch": "master",
                        "git_sha": "a3bb0aa......",
                        "installed_by": ["modules"]
                    },
                    "multiqc": {
                        "branch": "master",
                        "git_sha": "b9cc3d1......",
                        "installed_by": ["modules"]
                    }
                }
            }
        }
    }
}
```

The `git_sha` pins each module to a specific commit — this is what makes
module installations reproducible across machines and time.

---

## Common error → fix mapping

| Error message | Cause | Fix |
|---|---|---|
| `Module 'FASTQC' not found` | Missing include or wrong path | Check `include { FASTQC } from './modules/nf-core/fastqc/main'` |
| `No such file or directory: modules/nf-core/fastqc/main.nf` | Module not installed | Run `nf-core modules install fastqc` |
| `Expected [tuple] but found [map]` | Passing `meta` directly instead of `[meta, reads]` | Wrap in a tuple: `[ meta, reads ]` |
| `MULTIQC: Unexpected number of inputs` | Wrong number of args to MULTIQC call | MULTIQC takes exactly 6 — add `[]` for optional ones |
| `Channel queue is empty` | Forgot `.collect()` before MULTIQC | Add `.collect()` after `.map { meta, zips -> zips }` |
| `nf-core lint: Local copy does not match remote` | You edited an installed module | Run `nf-core modules patch <tool>` to track changes |
