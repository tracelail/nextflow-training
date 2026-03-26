# Session 18 — Expected Outputs at Each Step

## Exercise 1 — First `nextflow lint` run

Running `nextflow lint -o concise .` on the starter pipeline should produce
output similar to the following (exact line numbers may vary):

```
main.nf
  6 warnings

modules/local/fastqc.nf
  2 warnings, 1 error

modules/local/trim_reads.nf
  1 warning

modules/local/summarise.nf
  1 warning
```

Running `nextflow lint .` (full mode) will show something like:

```
main.nf:1:1: warning: the use of import declarations is deprecated
main.nf:8:1: error: unexpected statement at top-level
main.nf:14:12: warning: the use of 'Channel' is deprecated — use 'channel' instead
main.nf:15:14: warning: the use of 'Channel' is deprecated — use 'channel' instead
main.nf:39:24: warning: the use of 'Channel' is deprecated — use 'channel' instead
main.nf:43:20: warning: implicit closure parameter 'it' is deprecated
...
modules/local/fastqc.nf:22:5: warning: the use of 'env FOO' is deprecated — use 'env 'FOO'' instead
modules/local/fastqc.nf:25:5: warning: the 'shell' section is deprecated — use 'script' instead
```

**If you see zero warnings on a fresh starter pipeline:** your Nextflow version
may differ. Enable strict mode first with `export NXF_SYNTAX_PARSER=v2`, then
re-run lint — that will surface all issues.

---

## Exercise 2 — After fixing all deprecated syntax

Running `nextflow lint -o concise .` should now show:

```
main.nf
  0 warnings

modules/local/fastqc.nf
  0 warnings

modules/local/trim_reads.nf
  0 warnings

modules/local/multiqc.nf
  0 warnings

modules/local/summarise.nf
  0 warnings
```

**Total: 0 warnings, 0 errors.**

---

## Exercise 3 — After enabling `NXF_SYNTAX_PARSER=v2`

If Exercise 2 was done correctly, `nextflow lint .` with the v2 parser enabled
should still report zero errors. If any remain, the error messages will now be
more specific — for example:

```
main.nf:8:1: error: Unexpected statement outside workflow/process/function block
```

Running the stub test:
```
nextflow run main.nf -stub -profile test
```

Expected terminal output (last few lines):
```
executor >  local (4)
[xx/xxxxxx] SAY_HELLO (SAMPLE_01) | 4 of 4 ✔
[xx/xxxxxx] COLLECT_GREETINGS     | 1 of 1 ✔
Pipeline completed!
...
```

The `onComplete:` section output should print the pipeline banner at the very end.

---

## Exercise 4 — After adding typed `params {}` block

Running without `--input`:
```bash
nextflow run main.nf -stub
```
Expected error:
```
ERROR ~ Missing required parameter: input
```

Running with `--input`:
```bash
nextflow run main.nf -stub --input sample_data/samplesheet.csv
```
Expected: pipeline proceeds normally.

Running with wrong type (if implemented):
```bash
nextflow run main.nf -stub --input sample_data/samplesheet.csv --repeat hello
```
Expected: type validation error for `--repeat` (if typed as Integer).

---

## Exercise 5 — After adding `onComplete:` and `onError:` sections

Successful run output (last 10 lines):
```
executor >  local (...)
[xx/xxxxxx] FASTQC (SAMPLE_01)   | 4 of 4 ✔
[xx/xxxxxx] TRIM_READS (SAMPLE_01) | 4 of 4 ✔
[xx/xxxxxx] MULTIQC              | 1 of 1 ✔
[xx/xxxxxx] SUMMARISE (SAMPLE_01)| 4 of 4 ✔
=========================================
Pipeline completed!
=========================================
Workflow : main.nf
Completed: ...
Duration : ...
Success  : true
Work dir : /path/to/work
Exit code: 0
=========================================
```

---

## Exercise 6 — Challenge: type annotations + full strict run

After adding type annotations to workflow takes/emits, lint should still report
zero warnings. The stub run should complete identically to Exercise 5.

Running with `-resume` after a successful run:
```
Cached tasks:
[xx/xxxxxx] FASTQC (SAMPLE_01)   | 4 of 4, cached ✔
[xx/xxxxxx] TRIM_READS (SAMPLE_01)| 4 of 4, cached ✔
...
```

All tasks should be listed as `cached` — confirming that adding strict syntax
and type annotations does not invalidate the resume cache.

---

## Syntax cheatsheet self-test

```bash
export NXF_SYNTAX_PARSER=v2
nextflow lint exercises/syntax_cheatsheet.nf
```

Expected:
```
exercises/syntax_cheatsheet.nf
  0 warnings, 0 errors
```

```bash
nextflow run exercises/syntax_cheatsheet.nf -stub
```

Expected:
```
executor >  local (4)
[xx/xxxxxx] SAY_HELLO (Alice) | 3 of 3 ✔
[xx/xxxxxx] COLLECT_GREETINGS | 1 of 1 ✔

Cheatsheet workflow complete! Duration: ...
```
