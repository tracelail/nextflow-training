# Session 13 — Expected Outputs Reference

This document describes what you should see at each stage of the exercises.
Use it to verify your runs completed correctly.

---

## Exercise 1: Test profile run

### Expected terminal output (abbreviated)

```
N E X T F L O W  ~  version 25.xx.x
Launching `https://github.com/nf-core/demo` [some_name] DSL2 - revision: xxxxxxx [1.1.0]

------------------------------------------------------
                                        ,--./,-.
        ___     __   __   __   ___     /,-._.--~'
  |\ | |__  __ /  ` /  \ |__) |__         }  {
  | \| |       \__, \__/ |  \ |___     \`-._,-`-,
                                        `._,._,'
  nf-core/demo v1.1.0
------------------------------------------------------
Core Nextflow options
  ...

Input/output options
  input  : https://raw.githubusercontent.com/...samplesheet_test_illumina_amplicon.csv
  outdir : results_exercise1

Max job request options
  max_cpus   : 4
  max_memory : 15.GB
  max_time   : 1.h

------------------------------------------------------
...
executor >  local (7)
[xx/xxxxxx] NFCORE_DEMO:DEMO:FASTQC (SAMPLE1_PE)       [100%] 3 of 3 ✔
[xx/xxxxxx] NFCORE_DEMO:DEMO:SEQTK_TRIM (SAMPLE1_PE)   [100%] 3 of 3 ✔
[xx/xxxxxx] NFCORE_DEMO:DEMO:MULTIQC                    [100%] 1 of 1 ✔
-[nf-core/demo] Pipeline completed successfully -
Completed at: DD-MMM-YYYY HH:MM:SS
Duration    : ~1m 30s
CPU hours   : (a few)
Succeeded   : 7
```

### Expected output directory structure

```
results_exercise1/
├── fastqc/
│   ├── SAMPLE1_PE.html
│   ├── SAMPLE1_PE_fastqc.zip
│   ├── SAMPLE2_PE.html
│   ├── SAMPLE2_PE_fastqc.zip
│   ├── SAMPLE3_SE.html
│   └── SAMPLE3_SE_fastqc.zip
├── fq/
│   ├── SAMPLE1_PE_1.trim.fastq.gz
│   ├── SAMPLE1_PE_2.trim.fastq.gz
│   ├── SAMPLE2_PE_1.trim.fastq.gz
│   ├── SAMPLE2_PE_2.trim.fastq.gz
│   ├── SAMPLE3_SE_1.trim.fastq.gz
│   └── (no _2 for single-end sample)
├── multiqc/
│   ├── multiqc_report.html       ← open this in a browser
│   └── multiqc_data/
│       ├── multiqc_fastqc.json
│       ├── multiqc_general_stats.json
│       └── ...
└── pipeline_info/
    ├── execution_report.html     ← interactive task details
    ├── execution_timeline.html
    ├── execution_trace.txt
    ├── pipeline_dag.html
    └── nf_core_demo_software_mqc_versions.yml
```

### Verification commands

```bash
# Count the output files
ls results_exercise1/fastqc/*.html | wc -l
# Expected: 3  (one per sample)

ls results_exercise1/fq/*.fastq.gz | wc -l
# Expected: 5  (paired-end = 2 files each × 2 samples, single-end = 1 file × 1 sample)

# Check MultiQC report exists
ls -lh results_exercise1/multiqc/multiqc_report.html

# Check execution trace has the right number of tasks
wc -l results_exercise1/pipeline_info/execution_trace.txt
# Expected: 8 lines (1 header + 7 tasks: 3 FASTQC + 3 SEQTK_TRIM + 1 MULTIQC)
```

---

## Exercise 2: Params file run

### Expected nf-params.json content

```json
{
    "input": "sample_data/samplesheet.csv",
    "outdir": "results_custom"
}
```

### Expected output directory structure

Identical structure to Exercise 1, but under `results_custom/`, with your
three synthetic samples instead of the test pipeline samples:

```
results_custom/
├── fastqc/
│   ├── CONTROL_REP1.html
│   ├── CONTROL_REP1_fastqc.zip
│   ├── CONTROL_REP2.html
│   ├── CONTROL_REP2_fastqc.zip
│   ├── TREATMENT_REP1.html
│   └── TREATMENT_REP1_fastqc.zip
├── fq/
│   ├── CONTROL_REP1_1.trim.fastq.gz
│   ├── CONTROL_REP1_2.trim.fastq.gz
│   ├── CONTROL_REP2_1.trim.fastq.gz
│   ├── CONTROL_REP2_2.trim.fastq.gz
│   ├── TREATMENT_REP1_1.trim.fastq.gz
│   └── TREATMENT_REP1_2.trim.fastq.gz
├── multiqc/
│   └── multiqc_report.html
└── pipeline_info/
    └── ...
```

> **Note:** The synthetic FASTQ files contain random sequences with no
> real biological signal. FastQC will report them as failing several
> quality checks (GC content, duplication, etc.). This is expected and
> normal — these files exist only to demonstrate the pipeline mechanics.

---

## Exercise 3: Download and custom config

### Expected download directory structure

```
nf-core-demo-offline/
├── workflow/                       ← full pipeline code
│   ├── main.nf
│   ├── nextflow.config             ← patched to use ../configs/
│   ├── nextflow_schema.json
│   ├── CITATIONS.md
│   ├── CHANGELOG.md
│   ├── workflows/
│   │   └── demo.nf                ← main workflow logic
│   ├── subworkflows/
│   │   ├── local/
│   │   └── nf-core/
│   ├── modules/
│   │   ├── local/
│   │   └── nf-core/
│   │       ├── fastqc/
│   │       ├── multiqc/
│   │       └── seqtk/trim/
│   ├── conf/
│   │   ├── base.config
│   │   ├── modules.config
│   │   └── test.config
│   └── assets/
└── configs/                        ← institutional configs (nf-core/configs)
    ├── nfcore_custom.config
    └── conf/
        └── (institution-specific configs)
```

### Expected run output with custom config

The run should complete successfully with the same structure as Exercise 1.
The difference is visible in the MultiQC report title — it should show
"Session 13 Custom Run" instead of the default "nf-core/demo" title
(because of `ext.args = '--title "Session 13 Custom Run"'` in my_custom.config).

### Verification: confirm custom config was applied

```bash
# The MultiQC report title should contain your custom title
grep -i "Session 13 Custom Run" results_exercise3/multiqc/multiqc_report.html
# Expected: one or more lines containing the custom title text

# Check that FastQC output is still correct
ls results_exercise3/fastqc/*.html | wc -l
# Expected: 3
```

---

## Common output to check in ALL exercises

### execution_trace.txt columns

```
task_id  hash    native_id  name                                    status  exit  ...
1        xx/xx   -          NFCORE_DEMO:DEMO:FASTQC (SAMPLE1_PE)   COMPLETED  0  ...
2        xx/xx   -          NFCORE_DEMO:DEMO:FASTQC (SAMPLE2_PE)   COMPLETED  0  ...
...
```

Key columns to understand:
- `status` — should be `COMPLETED` for all tasks
- `exit` — should be `0` for all tasks (non-zero = error)
- `hash` — the 8-character work directory hash (use to find `.command.sh`, `.command.err`)
- `duration` — how long the task took
- `realtime` — actual CPU time
- `%cpu` — CPU utilisation

### Software versions

```bash
cat results_exercise1/pipeline_info/nf_core_demo_software_mqc_versions.yml
```

This YAML file lists the exact version of every tool used. In a real
bioinformatics context this is critical for methods sections in publications
and for reproducibility audits.
