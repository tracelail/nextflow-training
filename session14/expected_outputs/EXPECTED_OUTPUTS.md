# Session 14 — Expected Outputs

## Exercise 1: Template exploration

After running `nf-core pipelines create` you should see a directory like:

```
nf-core-greetings/
├── main.nf
├── nextflow.config
├── nextflow_schema.json
├── modules.json
├── .nf-core.yml
├── workflows/
│   └── greetings.nf
├── subworkflows/
│   ├── local/utils_nfcore_greetings_pipeline/main.nf
│   └── nf-core/
├── conf/
│   ├── base.config
│   ├── modules.config
│   ├── test.config
│   └── test_full.config
└── assets/
    ├── schema_input.json
    └── ...
```

Key things to verify after reading main.nf:
- You can identify the unnamed `workflow {}` entry point
- You can find where `PIPELINE_INITIALISATION` is called
- You can see the `take:` / `main:` / `emit:` blocks in `NFCORE_GREETINGS`
- You understand that `GREETINGS` (in workflows/greetings.nf) is the core logic

---

## Exercise 2: Adding a local process

After running:
```bash
nextflow run main.nf --input assets/samplesheet.csv --outdir results
```

Expected terminal output:
```
executor >  local (6)
[xx/xxxxxx] SAY_HELLO (sample1) [100%] 6 of 6 ✔
```

Expected results directory:
```
results/
└── greetings/
    ├── sample1.txt
    ├── sample2.txt
    ├── sample3.txt
    ├── sample4.txt
    ├── sample5.txt
    └── sample6.txt
```

Expected content of results/greetings/sample1.txt:
```
Hello from sample1 (nf-core training)
```

Expected content of results/greetings/sample2.txt:
```
Bonjour from sample2 (nf-core training)
```

Note: versions.yml is NOT in results/greetings/ because the saveAs filter
in modules.config returns null for it.

---

## Exercise 3: nf-core conversion of Session 3 pipeline

After running:
```bash
nextflow run main.nf --input assets/samplesheet.csv --outdir results
```

Expected terminal output:
```
executor >  local (7)
[xx/xxxxxx] SAY_HELLO (sample1)     [100%] 3 of 3 ✔
[xx/xxxxxx] CONVERT_UPPER (sample1) [100%] 3 of 3 ✔
[xx/xxxxxx] COLLECT_RESULTS         [100%] 1 of 1 ✔
```

Expected results directory structure:
```
results/
├── greetings/
│   ├── sample1.txt
│   ├── sample2.txt
│   └── sample3.txt
├── upper/
│   ├── sample1.upper.txt
│   ├── sample2.upper.txt
│   └── sample3.upper.txt
├── collected/
│   └── all_greetings.txt
└── pipeline_info/
    ├── pipeline_dag.html
    ├── pipeline_report.html
    ├── pipeline_timeline.html
    └── pipeline_trace.txt
```

Expected content of results/greetings/sample1.txt:
```
Hello from sample1
```

Expected content of results/upper/sample1.upper.txt:
```
HELLO FROM SAMPLE1
```

Expected content of results/collected/all_greetings.txt:
```
=== All Greetings (uppercased) ===
Generated: Tue Mar 10 ...

HELLO FROM SAMPLE1
BONJOUR FROM SAMPLE2
HOLÀ FROM SAMPLE3
```

Note: The order of greetings in all_greetings.txt may vary because Nextflow
processes run in parallel. The exact order depends on which task finishes first.
This is expected behaviour — Nextflow does not guarantee channel ordering.

---

## How to verify process names

After any successful run, check the trace file to see fully qualified process names:
```bash
cat results/pipeline_info/pipeline_trace.txt | cut -f5
```

You should see entries like:
```
NFCORE_GREETINGS:GREETINGS:SAY_HELLO (sample1)
NFCORE_GREETINGS:GREETINGS:CONVERT_UPPER (sample2)
NFCORE_GREETINGS:GREETINGS:COLLECT_RESULTS
```

The `withName: 'SAY_HELLO'` selector in modules.config matches any process
whose full path ENDS in SAY_HELLO. To target only this specific invocation
you would write:
```groovy
withName: 'NFCORE_GREETINGS:GREETINGS:SAY_HELLO'
```

---

## Resume verification

After a successful run, try:
```bash
nextflow run main.nf --input assets/samplesheet.csv --outdir results -resume
```

All tasks should show `[cached]`. Then modify ext.args for SAY_HELLO in
conf/modules.config (e.g., change '' to '(modified)') and re-run with -resume.

Expected: SAY_HELLO re-runs, CONVERT_UPPER re-runs (input changed), COLLECT_RESULTS re-runs.
This confirms that changing config re-invalidates the cache as expected.
