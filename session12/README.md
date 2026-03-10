# Session 12 — nf-test: Writing Tests for Your Pipeline

## Learning Objectives

By the end of this session you will be able to:

- Explain what nf-test is and why testing pipelines matters
- Initialize nf-test in a project with `nf-test init`
- Write **pipeline-level tests** using `nextflow_pipeline {}` to assert on overall pipeline success and task count
- Write **process-level tests** using `nextflow_process {}` to assert on individual process outputs
- Use **snapshot testing** (`assert snapshot(...).match()`) to catch regressions
- Run, filter, and update tests with the `nf-test test` CLI

---

## Prerequisites

- Sessions 1–11 complete
- The pipeline from Session 4 (modular) is what we are adding tests to here — this session ships a self-contained version so you do not need those exact files
- nf-test installed: `pip install nf-test` or via conda/mamba
  Verify: `nf-test version` → should show `0.9.x`

---

## Concepts

### Why test a pipeline?

A Nextflow pipeline can produce wrong results silently. A process might succeed (exit code 0) but write an empty file, or produce output that is off by one row. Without automated tests you only catch these failures by manually inspecting outputs — which does not scale and does not catch regressions when you change something later.

nf-test solves this by letting you write assertions about your pipeline in the same language it is built in (Groovy/Nextflow DSL). You can check that the pipeline succeeded, that the right number of tasks ran, that output files contain specific content, and that outputs have not changed unexpectedly since the last run (snapshot testing).

### The three test scopes

nf-test supports three levels of testing, each with its own block type:

| Block | What it tests | What you assert on |
|---|---|---|
| `nextflow_pipeline {}` | The entire pipeline from `main.nf` | `workflow.success`, task count, output files |
| `nextflow_process {}` | A single process in isolation | `process.success`, `process.out.<emit_name>` |
| `nextflow_workflow {}` | A named sub-workflow | `workflow.success`, `workflow.out.<emit_name>` |

In this session we focus on `nextflow_pipeline` and `nextflow_process`.

### The when/then structure

Every test follows the same pattern:

```groovy
test("description of what this test checks") {

    when {
        // Set up inputs and params here
        params {
            input = "path/to/samplesheet.csv"
        }
    }

    then {
        // Assert on results here
        assert workflow.success
    }
}
```

The `when {}` block describes the inputs. The `then {}` block contains assertions. If any `assert` fails, nf-test reports exactly which assertion failed and what the values were (this is called a "power assertion").

### Snapshot testing

A snapshot captures the current output of a process or workflow and saves it to a `.snap` JSON file. On the next run, nf-test compares the current output to the saved snapshot. If anything has changed, the test fails — this is how you catch regressions.

First run (creates the snapshot):
```
nf-test test tests/say_hello.nf.test
```

After you intentionally change the process (and the output changes on purpose):
```
nf-test test tests/say_hello.nf.test --update-snapshot
```

Snapshot files (`*.nf.test.snap`) should be **committed to version control** — they are the record of what "correct" output looks like.

---

## Hands-On Exercises

### Step 0 — Explore the project structure

The session directory contains a complete three-process pipeline. Take a minute to read through the files before writing any tests:

```
session12/
├── main.nf                          ← the pipeline
├── nextflow.config
├── nf-test.config                   ← tells nf-test where tests live
├── data/
│   └── samplesheet/
│       ├── greetings.csv            ← 6-sample input
│       └── single_sample.csv        ← 1-sample input for one test
├── modules/local/
│   ├── say_hello.nf                 ← Process 1: format greeting
│   ├── convert_upper.nf             ← Process 2: uppercase it
│   └── collect_results.nf           ← Process 3: gather + summarise
└── tests/
    ├── main.nf.test                 ← pipeline-level tests (Exercise A)
    ├── say_hello.nf.test            ← process-level tests (Exercise B)
    ├── convert_upper.nf.test        ← process-level tests (Exercise C)
    └── collect_results.nf.test      ← process-level tests (Exercise D)
```

Open `main.nf` and trace the data flow:
1. `channel.fromPath` + `splitCsv` → reads greetings.csv into `[meta, greeting]` tuples
2. `SAY_HELLO` formats each greeting as `"sample_id: greeting"`
3. `CONVERT_UPPER` uppercases the result
4. `.collect()` gathers all results into one list, `COLLECT_RESULTS` produces a summary

Run the pipeline once to make sure it works:

```bash
cd session12
nextflow run main.nf
```

You should see output like:
```
SUMMARY: Processed 6 greetings: SAMPLE_01: HELLO | SAMPLE_02: BONJOUR | ...
```

---

### Exercise A — BASIC: Run the first pipeline-level test

Open `tests/main.nf.test`. Read Test 1 carefully. Notice:
- The `nextflow_pipeline {}` block declares the script as `"../main.nf"` (relative to the tests/ directory)
- The `when { params {} }` block sets `input` and `outdir`
- The `then {}` block asserts `workflow.success` and task counts

Run only Test 1:

```bash
nf-test test tests/main.nf.test --filter "Pipeline should complete without failures"
```

You should see:
```
✅  Test Pipeline should complete without failures PASSED (Xs)
```

**Understand the task count.** The pipeline has:
- 6 samples × SAY_HELLO = 6 tasks
- 6 samples × CONVERT_UPPER = 6 tasks
- 1 × COLLECT_RESULTS = 1 task
- Total = **13 tasks**

Change the assertion to `== 5` and re-run. Watch it fail with a clear message showing what value was actually returned. Change it back to `== 13`.

---

### Exercise B — BASIC: Run the first process-level test

Open `tests/say_hello.nf.test`. Read Test 1. Notice:
- The `nextflow_process {}` block declares both `script` and `process`
- `input[0]` inside `when { process {} }` feeds the first declared input of `SAY_HELLO`
- `process.out.result` accesses the `emit: result` output channel
- `.get(0)` retrieves the first element from the output channel

Run it:

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO should format a greeting correctly"
```

**Now modify the test.** Change the greeting from `'Hello'` to `'Greetings'`. Update the assertion on `output[1]` to match. Re-run. It should pass.

Change it back when you are done.

---

### Exercise C — INTERMEDIATE: Write your own process assertion

Open `tests/say_hello.nf.test`. Test 2 runs SAY_HELLO with three samples. The test collects all output strings and sorts them before comparing.

**Why sort?** Channel element order is not guaranteed in Nextflow. If you assert `formatted[0] == 'sample_01: Hello'` without sorting, the test might fail on some runs depending on which task finished first. Sorting makes the comparison deterministic.

Run Test 2:

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO should handle multiple samples"
```

**Your task:** Add a fourth sample to Test 2's input channel:

```groovy
[ [id: 'sample_04', language: 'Italian'], 'Ciao' ]
```

Update the `assert formatted == [...]` list to include `'sample_04: Ciao'` in the correct sorted position. Re-run to confirm it passes.

---

### Exercise D — INTERMEDIATE: Create your first snapshot

Snapshots are how you lock in "this is correct" and detect future regressions.

Run the snapshot test for `SAY_HELLO` (Test 3):

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO output should match snapshot"
```

The first run **creates** the snapshot file. Look at what was created:

```bash
cat tests/say_hello.nf.test.snap
```

You will see a JSON file with the serialized output. Note that val outputs are stored as their literal values.

Now **simulate a regression**: open `modules/local/say_hello.nf` and change the output format from `"${meta.id}: ${greeting}"` to `"[${meta.id}] ${greeting}"`. Re-run the snapshot test:

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO output should match snapshot"
```

It should **fail** — the output no longer matches the stored snapshot. This is nf-test catching your change.

Now decide: was this change intentional? If yes, update the snapshot:

```bash
nf-test test tests/say_hello.nf.test --update-snapshot
```

Revert the format change back to `"${meta.id}: ${greeting}"` and update the snapshot again to restore the correct baseline.

---

### Exercise E — INTERMEDIATE: Run the chained test with setup {}

Open `tests/convert_upper.nf.test`. Test 2 uses a `setup {}` block to run `SAY_HELLO` first, then feeds its output into `CONVERT_UPPER`. This mimics the real pipeline chain.

Run it:

```bash
nf-test test tests/convert_upper.nf.test --filter "CONVERT_UPPER should work on SAY_HELLO output via setup"
```

Trace through the logic:
1. `setup {}` runs SAY_HELLO with `'Bonjour'` → emits `'chain_test: Bonjour'`
2. `when { process {} }` feeds `SAY_HELLO.out.result` into CONVERT_UPPER
3. `then {}` asserts the output is `'CHAIN_TEST: BONJOUR'`

**Question to consider:** Why might you prefer pre-generated test data files over `setup {}` for a production module? (Hint: think about what happens to your CONVERT_UPPER test if SAY_HELLO has a bug.)

---

### Exercise F — CHALLENGE: Run the full test suite and understand snapshot files

Run every test in the project at once:

```bash
nf-test test
```

After all tests pass, examine the snapshot files that were created:

```bash
ls tests/*.snap
cat tests/say_hello.nf.test.snap
cat tests/convert_upper.nf.test.snap
```

Now run in **CI mode** — this prevents nf-test from creating new snapshots and fails instead:

```bash
nf-test test --ci
```

All tests should still pass (snapshots already exist). Delete one snapshot file and re-run with `--ci`:

```bash
rm tests/say_hello.nf.test.snap
nf-test test --ci
```

It should fail because no snapshot exists and `--ci` forbids creating new ones. Re-run without `--ci` to regenerate it:

```bash
nf-test test tests/say_hello.nf.test
```

---

### Exercise G — CHALLENGE: Write a new test from scratch

You now have all the pieces. Write a **new test** inside `tests/say_hello.nf.test` for this scenario:

> "SAY_HELLO receives a sample with a multi-word greeting"

Requirements:
- Input: `[id: 'sample_x', language: 'English']`, greeting: `'Good morning'`
- Assert: `process.success` is true
- Assert: `output[1]` equals `'sample_x: Good morning'`
- Assert: the metadata field `output[0].language` equals `'English'`

Add it as a fourth `test("...")` block after the existing three, then run only your new test:

```bash
nf-test test tests/say_hello.nf.test --filter "your test name here"
```

---

## Debugging Tips

**1. "No tests found" or "script not found"**
nf-test resolves `script` paths relative to the test file's location. From `tests/say_hello.nf.test`, the module is at `../modules/local/say_hello.nf`. Double-check the relative path. Also confirm `nf-test.config` exists in the project root.

**2. Task count assertion fails unexpectedly**
Re-run the pipeline with `.view()` on each channel to count how many elements flow through each process. Remember: `collect()` converts a multi-element queue channel into a single-element value channel, so `COLLECT_RESULTS` always runs exactly once regardless of sample count.

**3. Snapshot test always fails on re-run**
Your process produces non-deterministic output (e.g., timestamps, random IDs). Switch from `snapshot().match()` to content assertions: `assert process.out.result.get(0)[1].contains("expected_substring")`.

**4. `process.out.channel_name` is null**
The emit name in the process output block must match exactly. Check that `emit: result` in `say_hello.nf` matches `process.out.result` in your test. Case is significant.

**5. setup {} test fails but direct input test passes**
The process being run in `setup {}` has a bug or unexpected output. Add `.view()` inside a temporary test to inspect the setup process output, or switch to pre-generated test data to remove the dependency.

---

## Key Takeaways

- nf-test gives you three test scopes (pipeline, process, workflow) to test at the right level of granularity: pipeline tests verify end-to-end behaviour, process tests verify individual logic in isolation.
- The `input[N]` array syntax in `when { process {} }` mirrors exactly how Nextflow feeds data into a process, making test inputs intuitive to write.
- Snapshot files are your regression safety net — commit them to version control and update them only when output changes are intentional.

---

## Reference: Key nf-test assertions

```groovy
// Workflow / pipeline level
assert workflow.success
assert workflow.trace.tasks().size() == 13
assert workflow.trace.succeeded().size() == 13
assert workflow.trace.failed().size() == 0
assert "text" in workflow.stdout

// Process level
assert process.success
assert process.out.channel_name != null
assert process.out.channel_name.size() == 3
def item = process.out.channel_name.get(0)

// Path assertions (when output is a file path)
assert path(process.out.files.get(0)).exists()
assert path(process.out.files.get(0)).text.contains("hello")
assert path(process.out.files.get(0)).readLines().size() == 6

// Snapshot
assert snapshot(process.out).match()
assert snapshot(workflow).match()

// Scoped with()
with(process.out.summary) {
    assert size() == 1
    assert get(0).contains("expected text")
}
```

## CLI Quick Reference

```bash
nf-test init                          # initialise project (creates nf-test.config)
nf-test generate pipeline main.nf     # scaffold a pipeline test file
nf-test generate process modules/local/say_hello.nf

nf-test test                          # run all tests
nf-test test tests/say_hello.nf.test  # run one test file
nf-test test --filter "test name"     # run tests matching a name substring
nf-test test --update-snapshot        # regenerate snapshots for failing tests
nf-test test --ci                     # CI mode: fail on missing snapshots
nf-test test --verbose                # show full Nextflow output
```
