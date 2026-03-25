# Session 16 — Expected Outputs

## Step 3: nextflow run main.nf -profile conda

```
N E X T F L O W  ~  version 25.04.6
Launching `main.nf` [jovial_darwin] DSL2 - revision: abc12345

executor >  local (3)
[12/abc123] SEQTK_SEQ (sample1) | 3 of 3 ✔
✓ sample1: sample1.fasta.gz
✓ sample2: sample2.fasta.gz
✓ sample3: sample3.fasta.gz

Pipeline completed: SUCCESS
Execution time   : 4s
Results          : /path/to/session16/results
```

### results/ directory after a successful run:
```
results/
└── seqtk/
    └── seq/
        ├── sample1.fasta.gz
        ├── sample2.fasta.gz
        └── sample3.fasta.gz
```

### Inspecting one output file:
```bash
zcat results/seqtk/seq/sample1.fasta.gz
```
Expected:
```
>sample1_read1 length=20
ATCGATCGATCGATCGATCG
>sample1_read2 length=20
GCTAGCTAGCTAGCTAGCTA
>sample1_read3 length=20
TTTTAAAACCCCGGGGTTTT
```

Differences from the input FASTQ:
- `@` header becomes `>` (FASTA format)
- Quality score lines (`+` and `IIII...`) are removed

---

## Step 4: nf-test stub run

```bash
cd modules/local/seqtk/seq
nf-test test tests/main.nf.test --profile conda
```

Expected output:
```
🚀 nf-test 0.9.2
  → Loading /path/to/session16/nextflow.config

Test Process SEQTK_SEQ

  Test [fastq single-end - stub]
    → Process 'SEQTK_SEQ' uses stub
    PASSED (1.3s)

SUCCESS: 1 tests, 1 passed, 0 failed (1.3s)
```

If the snapshot md5 does not match your environment, regenerate it:
```bash
nf-test test tests/main.nf.test --update-snapshot --profile conda
```

---

## Basic Exercise: Completed SEQTK_TRIMFQ

After correctly filling in `modules/local/seqtk/trimfq/main.nf`, it should
match `solutions/seqtk/trimfq/main.nf`.

Key things to verify before running:

1. `tag "$meta.id"` — uses `$meta.id` not `${meta.id}` (both work but
   the single-dollar form is the nf-core convention in the tag directive)

2. `label 'process_single'` — seqtk is single-threaded

3. Container block uses the TERNARY expression — not two separate `container`
   directives

4. Output block has TWO entries: the trimmed FASTQ tuple AND the topic
   channel version tuple

5. `def args` and `def prefix` appear before `"""` in BOTH script and stub

6. The stub creates `${prefix}.fastq.gz` with `echo "" | gzip --no-name`

---

## Intermediate Exercise: Completed meta.yml

Check your `meta.yml` against `solutions/seqtk/trimfq/meta.yml`.

Things lint will check:
- `identifier: biotools:seqtk` is present under the tool entry
- Each file input/output has at least one `ontologies:` entry with a valid EDAM URL
- Channel-grouped format is correct (tuple channels use `- -` double-dash prefix)
- `authors:` list is present

---

## Challenge Exercise: nf-test stub test

After running `--update-snapshot`, your `tests/main.nf.test.snap` should
contain something like:

```json
{
  "fastq single-end - stub": {
    "content": [
      {
        "trimmed": [
          [
            { "id": "test", "single_end": true },
            "test.fastq.gz:md5,1a60c330fb42841e8dcf3cd507a70bfc"
          ]
        ],
        "versions_seqtk": [
          [ "SEQTK_TRIMFQ", "seqtk", "1.4-r122" ]
        ]
      }
    ]
  }
}
```

The md5 `1a60c330fb42841e8dcf3cd507a70bfc` is the checksum of an empty gzip
file (`echo "" | gzip --no-name`). Every stub .gz output will have this same
checksum.

---

## nf-core modules lint output (reference)

When run against a well-formed module:
```
╭─ [✔] SEQTK_SEQ ─────────────────────────────────────────────────────╮
│  PASSED: main_nf_exists                                              │
│  PASSED: environment_yml_exists                                      │
│  PASSED: meta_yml_exists                                             │
│  PASSED: tests_exist                                                 │
│  PASSED: meta_yml_valid                                              │
│  PASSED: has_stub                                                    │
│  PASSED: container_valid                                             │
│  PASSED: process_label_valid                                         │
│  PASSED: when_clause_correct                                         │
╰──────────────────────────────────────────────────────────────────────╯
```

Common warnings and fixes:

| Warning | Cause | Fix |
|---|---|---|
| `meta_yml: missing ontology` | An input/output file has no EDAM URL | Add `ontologies: - edam: "http://..."` |
| `meta_yml: identifier missing` | No `identifier: biotools:...` on the tool | Add `identifier: biotools:<name>` |
| `has_stub: stub missing` | No `stub:` block at all | Add a stub block |
| `stub creates no files` | Stub block has no `touch` or `echo | gzip` | Add file creation commands |
| `container_valid: not quay.io` | Using `biocontainers/` Docker Hub URL | Swap to `quay.io/biocontainers/` |
