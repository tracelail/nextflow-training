# VERIFICATION — Session 11 Expected Outputs

Use this checklist to confirm you have completed each exercise correctly.

---

## Exercise 1 — Resume Demo

### First run (fresh)
```
executor >  local (8)
[xx/xxxxxx] REVERSE_TEXT (sampleA) [100%] 1 of 1 ✔
[xx/xxxxxx] REVERSE_TEXT (sampleB) [100%] 1 of 1 ✔
[xx/xxxxxx] REVERSE_TEXT (sampleC) [100%] 1 of 1 ✔
[xx/xxxxxx] REVERSE_TEXT (sampleD) [100%] 1 of 1 ✔
[xx/xxxxxx] COUNT_WORDS  (sampleA) [100%] 1 of 1 ✔
[xx/xxxxxx] COUNT_WORDS  (sampleB) [100%] 1 of 1 ✔
[xx/xxxxxx] COUNT_WORDS  (sampleC) [100%] 1 of 1 ✔
[xx/xxxxxx] COUNT_WORDS  (sampleD) [100%] 1 of 1 ✔
```

### Second run with -resume (nothing changed)
All 8 tasks should show `cached: 1`. The `executor > local (0)` line confirms no new tasks ran.

### After modifying COUNT_WORDS and re-running with -resume
```
REVERSE_TEXT (sampleA) — cached: 1  ← hash unchanged, skipped
REVERSE_TEXT (sampleB) — cached: 1
REVERSE_TEXT (sampleC) — cached: 1
REVERSE_TEXT (sampleD) — cached: 1
COUNT_WORDS  (sampleA) — [re-executed]  ← new hash, ran fresh
COUNT_WORDS  (sampleB) — [re-executed]
COUNT_WORDS  (sampleC) — [re-executed]
COUNT_WORDS  (sampleD) — [re-executed]
```

### Work directory inspection
After `cat work/xx/xxxxxx*/.command.sh`, you should see the fully interpolated script with resolved values, not Nextflow variable names:
```bash
#!/bin/bash -ue
rev sampleA.txt > sampleA_reversed.txt
```

### Output files
```
results/
├── reversed/
│   ├── sampleA_reversed.txt
│   ├── sampleB_reversed.txt
│   ├── sampleC_reversed.txt
│   └── sampleD_reversed.txt
└── counts/
    ├── sampleA_count.txt
    ├── sampleB_count.txt
    ├── sampleC_count.txt
    └── sampleD_count.txt
```

Content of `results/counts/sampleA_count.txt` (before script change):
```
Words: 36
```

Content of `results/counts/sampleA_count.txt` (after script change):
```
Word count for sampleA: 36
```

---

## Exercise 2 — Cache Invalidation

### Invalidation A: Touch experiment

After `touch data/sampleA.txt`:
```
[xx/xxxxxx] MEASURE_LENGTH (sampleA) — [re-executed]  ← timestamp changed!
[xx/xxxxxx] MEASURE_LENGTH (sampleB) — cached: 1
[xx/xxxxxx] MEASURE_LENGTH (sampleC) — cached: 1
[xx/xxxxxx] MEASURE_LENGTH (sampleD) — cached: 1
```

After adding `cache 'lenient'` and touching again:
```
[xx/xxxxxx] MEASURE_LENGTH (sampleA) — cached: 1  ← lenient ignores timestamp
```

### Invalidation B: Race condition

The `.view()` output for RACE DEMO will vary between runs. Sometimes you see:
```
RACE DEMO sampleA: counter=7
RACE DEMO sampleB: counter=7
```
Other times:
```
RACE DEMO sampleA: counter=14
RACE DEMO sampleB: counter=7
```
After adding `def SHARED_COUNTER = 0`, the output stabilizes:
```
RACE DEMO sampleA: counter=7
RACE DEMO sampleB: counter=7
RACE DEMO sampleC: counter=7
RACE DEMO sampleD: counter=7
```

### Invalidation C: Non-deterministic ordering

Running `nextflow log <run1> -f 'process,tag,hash'` vs `nextflow log <run2> -f 'process,tag,hash'`:

| Process | Tag | Run 1 hash | Run 2 hash |
|---------|-----|-----------|-----------|
| MEASURE_LENGTH | sampleA | `7b/1a2c3d` | `7b/1a2c3d` | ← stable |
| UPPERCASE_TEXT | sampleA | `3c/4d5e6f` | `3c/4d5e6f` | ← stable |
| COMBINE_RESULTS | sampleA | `8f/9a0b1c` | `2d/3e4f5a` | ← UNSTABLE |

After applying the `join()` fix, all hashes stabilize across runs.

---

## Exercise 3 — nextflow log Forensics

### Expected nextflow log output
```
TIMESTAMP            DURATION  RUN NAME          STATUS  REVISION ID  SESSION ID
2026-xx-xx xx:xx:xx  3.2s      happy_curie       OK      ...          ...
```

### nextflow log <run_name> -f 'process,exit,hash,duration'
```
COUNT_LINES     0  ab/12cdef  0.3s
COUNT_LINES     0  3d/45ef01  0.2s
COUNT_LINES     0  7f/890123  0.3s
COUNT_LINES     0  cd/456789  0.2s
EXTRACT_FIRST_LINE  0  ...
SUMMARIZE       0  ...
```

### Provenance HTML report
After running `nextflow log <run> -t scripts/log_template.html > results/provenance.html`:
- File exists at `results/provenance.html`
- Opening in a browser shows one styled card per task
- Each card shows: task name, status, exit code, duration, container, work dir, script

### Summary report contents
```
=== Pipeline Summary Report ===
Generated: Mon Mar  2 ...

--- Line counts ---
sampleA: 5 lines
sampleB: 5 lines
sampleC: 5 lines
sampleD: 5 lines

--- First lines ---
The quick brown fox jumps over the lazy dog.
To be or not to be that is the question...
It was the best of times it was the worst of times.
Call me Ishmael some years ago...
```

---

## Exercise 4 — Stub Runs and Preview Mode

### nextflow lint (expected output)
```
Nextflow 25.04.6 — No issues found in exercises/04_stub_preview.nf
```
(or warnings if any 2026 syntax violations remain)

### -preview output
```
Nextflow 25.04.6 preview mode — workflow validated, no tasks executed.
```

### -stub-run output
```
executor >  local (5)
[xx/xxxxxx] SIMULATE_ALIGNMENT (sampleA) [100%] 1 of 1 ✔
[xx/xxxxxx] SIMULATE_ALIGNMENT (sampleB) [100%] 1 of 1 ✔
[xx/xxxxxx] SIMULATE_ALIGNMENT (sampleC) [100%] 1 of 1 ✔
[xx/xxxxxx] SIMULATE_ALIGNMENT (sampleD) [100%] 1 of 1 ✔
[xx/xxxxxx] SIMULATE_QC        (sampleA) [100%] 1 of 1 ✔
... (4 QC tasks)
[xx/xxxxxx] SUMMARIZE_RESULTS           [100%] 1 of 1 ✔
```

Output files exist but are empty (0 bytes), which is correct for stub mode:
```bash
ls -la results/aligned/
# -rw-r--r-- 1 user group 0 ... sampleA_aligned.txt  ← empty, expected
```

### After adding stub: to SUMMARIZE_RESULTS
```
results/summary.txt  ← exists, empty, correct
```

---

## Exercise 5 — Buggy Workflow (Solutions)

### Bug inventory (answers)

| # | Phase | Location | Bug | Fix |
|---|-------|----------|-----|-----|
| 1 | Phase 3 (stub-run) | PREPARE_SAMPLES output: | Filename mismatch: declares `_prepared.txt`, script creates `_clean.txt` | Change output to `"${meta.id}_clean.txt"` |
| 2 | Phase 4 (full run) | ANALYZE_SAMPLE script: | Unescaped `$WORD_COUNT` and `$(wc ...)` — Nextflow tries to interpolate them | Escape as `\$WORD_COUNT` and `\$(wc ...)` |
| 3 | Phase 1 (lint) | SCORE_SAMPLE | Deprecated `shell:` block | Replace with `script:` block, change `!{var}` to `${var}` |
| 4 | Phase 3 (stub-run) | AGGREGATE_RESULTS input: | `val` used for file inputs — Nextflow doesn't stage files passed as val | Change `val` to `path` |
| 5 | Phase 1 (lint) | workflow | `Channel.fromPath` — uppercase C is deprecated | Change to `channel.fromPath` |
| 6 | Phase 1 (lint) | workflow map closure | `meta = [...]` without `def` — race condition | Change to `def meta = [...]` |
| 7 | Phase 3 (stub-run) | workflow | `ANALYZE_SAMPLE(raw_ch)` — should receive prepared files | Change to `ANALYZE_SAMPLE(PREPARE_SAMPLES.out)` |
| 8 | Phase 3/4 | workflow | `AGGREGATE_RESULTS.out.report` — emit name doesn't exist | Add `emit: report` to AGGREGATE_RESULTS output block |

### Successful final run output
```
executor >  local (9)
[xx/xxxxxx] PREPARE_SAMPLES  (sampleA) [100%] 4 of 4 ✔
[xx/xxxxxx] ANALYZE_SAMPLE   (sampleA) [100%] 4 of 4 ✔
[xx/xxxxxx] SCORE_SAMPLE     (sampleA) [100%] 4 of 4 ✔
[xx/xxxxxx] AGGREGATE_RESULTS          [100%] 1 of 1 ✔

Pipeline completed. Check results/final_report.txt
```

### final_report.txt contents
```
=== Final Report ===
Date: Mon Mar  2 ...

--- Analysis ---
Analysis for sampleA:
  Words:  36
  Type:   control
Analysis for sampleB:
  Words:  40
  Type:   treatment
...

--- Scores ---
SCORE=baseline
SCORE=experimental
...
```
