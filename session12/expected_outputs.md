# Session 12 — Expected Outputs

This file shows what you should see at each stage so you can verify your results.

---

## Step 0: Running the pipeline directly

```bash
nextflow run main.nf
```

Expected terminal output (order of lines may vary):
```
N E X T F L O W  ~  version 25.04.6
executor >  local (13)
[xx/xxxxxx] SAY_HELLO (sample_01)     | 6 of 6 ✔
[xx/xxxxxx] CONVERT_UPPER (sample_01) | 6 of 6 ✔
[xx/xxxxxx] COLLECT_RESULTS           | 1 of 1 ✔
SUMMARY: Processed 6 greetings: SAMPLE_01: HELLO | SAMPLE_02: BONJOUR | SAMPLE_03: HOLA | SAMPLE_04: CIAO | SAMPLE_05: KONNICHIWA | SAMPLE_06: HALLO
```

---

## Exercise A: First pipeline test

```bash
nf-test test tests/main.nf.test --filter "Pipeline should complete without failures"
```

Expected:
```
🚀 nf-test 0.9.x
 ✅  Test Pipeline should complete without failures PASSED (Xs)

SUCCESS: Executed 1 tests in Xs
```

---

## Exercise B: First process test

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO should format a greeting correctly"
```

Expected:
```
 ✅  Test SAY_HELLO should format a greeting correctly PASSED (Xs)

SUCCESS: Executed 1 tests in Xs
```

---

## Exercise D: First snapshot creation

```bash
nf-test test tests/say_hello.nf.test --filter "SAY_HELLO output should match snapshot"
```

On first run (snapshot created):
```
 ✅  Test SAY_HELLO output should match snapshot PASSED (Xs)
```

After intentionally breaking the format and re-running (regression caught):
```
 ❌  Test SAY_HELLO output should match snapshot FAILED

Snapshot does not match!
Expected:
  "snap_test: Hello"
Found:
  "[snap_test] Hello"
```

After `--update-snapshot`:
```
 ✅  Test SAY_HELLO output should match snapshot PASSED (Xs)
Updated 1 snapshot(s)
```

---

## Exercise F: Full test suite

```bash
nf-test test
```

Expected (after all snapshots exist):
```
🚀 nf-test 0.9.x

 ✅  Test Pipeline should complete without failures PASSED
 ✅  Test Pipeline should handle a single-sample samplesheet PASSED
 ✅  Test Pipeline output should match snapshot PASSED
 ✅  Test SAY_HELLO should format a greeting correctly PASSED
 ✅  Test SAY_HELLO should handle multiple samples PASSED
 ✅  Test SAY_HELLO output should match snapshot PASSED
 ✅  Test CONVERT_UPPER should uppercase the input text PASSED
 ✅  Test CONVERT_UPPER should work on SAY_HELLO output via setup PASSED
 ✅  Test CONVERT_UPPER all outputs should match snapshot PASSED
 ✅  Test COLLECT_RESULTS should produce a summary from two inputs PASSED
 ✅  Test COLLECT_RESULTS summary should match snapshot PASSED

SUCCESS: Executed 11 tests in Xs
```

---

## Snapshot file example

After running the SAY_HELLO snapshot test, inspect `tests/say_hello.nf.test.snap`:

```json
{
  "SAY_HELLO output should match snapshot": {
    "content": [
      {
        "result": [
          [
            { "id": "snap_test", "language": "English" },
            "snap_test: Hello"
          ]
        ]
      }
    ],
    "meta": {
      "nf-test": "0.9.x",
      "nextflow": "25.04.6"
    },
    "timestamp": "2026-..."
  }
}
```

Key things to note:
- The test name is the JSON key
- `val` outputs are stored as their literal values (strings, maps)
- `path` outputs would be stored as `"filename:md5,<hash>"` instead
- The `meta` block records which versions produced this snapshot
- The `timestamp` is informational only — it does not affect snapshot comparison

---

## Power assertion failure example

When an assertion fails, nf-test shows you exactly what happened:

```
assert process.out.result.get(0)[1] == 'sample_01: Hello'
       |       |   |      |     |
       |       |   |      |     "sample_01: HELLO"   ← actual value
       |       |   |      [meta_map, "sample_01: HELLO"]
       |       |   ChannelList[...]
       |       ChannelList
       ProcessResult
```

This "power assertion" output is one of nf-test's most useful debugging features — you never have to add print statements to understand what a value actually was.
