# Session 16 — Creating nf-core Modules: Building Reusable Components

## Learning Objectives

By the end of this session you will be able to:

- Describe the six-file structure of an nf-core module and explain the purpose of each file
- Write a compliant `main.nf` process using all required conventions (`tag`, `label`, `when`, `ext.args`, `task.ext.prefix`, stub block)
- Emit software versions using the 2026 **topic channel** pattern (`eval()` + `topic: versions`) instead of the deprecated `versions.yml` heredoc
- Write a channel-grouped `meta.yml` with EDAM ontology URLs and bio.tools identifiers
- Write a minimal `environment.yml` with pinned Bioconda/conda-forge dependencies
- Write nf-test tests including a stub test with snapshot assertions
- Run `nf-core modules lint` and interpret its output

---

## Prerequisites

- Sessions 1–15 completed
- A pipeline created from the nf-core template (Session 14) or at minimum an `nf-core` conda environment active
- `nf-core` tools v3.5.0+ installed (`nf-core --version`)
- `nf-test` v0.9.2+ installed (`nf-test version`)
- Docker or Conda available for running the test pipeline

---

## Concepts

### What makes a module "nf-core compliant"?

An nf-core module is not just a Nextflow process — it is a **portable, testable, lintable unit** that any pipeline can install and use. The rules exist so that 1,700+ modules in the community repository behave consistently. When you contribute a module, `nf-core modules lint` validates dozens of rules automatically. The key conventions are:

**Process name:** Always `TOOL_SUBTOOL` in UPPERCASE (e.g., `SEQTK_SEQ`). The directory path is always lowercase (`seqtk/seq/`).

**The six required files:**
```
modules/local/seqtk/seq/
├── main.nf             ← The process definition
├── meta.yml            ← Documentation: inputs, outputs, EDAM ontology
├── environment.yml     ← Conda dependency spec
└── tests/
    ├── main.nf.test    ← nf-test test definitions
    ├── main.nf.test.snap ← Snapshot file (auto-generated, committed to git)
    └── nextflow.config ← Test-specific config (ext.args for tests)
```

**The topic channel pattern for versions (2026 mandatory):**

The old approach wrote a `versions.yml` file inside every process. This required explicit channel-mixing in every subworkflow. The new approach uses Nextflow's built-in **topic channels** — a broadcast mechanism where every module emits its version tuple directly to a named topic, and the pipeline collects them automatically.

```nextflow
# OLD pattern (deprecated — still works but will fail lint Q2 2026):
output:
path "versions.yml", emit: versions

script:
"""
cat <<-END_VERSIONS > versions.yml
"${task.process}":
    seqtk: \$(seqtk 2>&1 | grep Version | sed 's/Version: //')
END_VERSIONS
"""

# NEW pattern (2026 standard):
output:
tuple val("${task.process}"), val('seqtk'), eval('seqtk 2>&1 | grep "^Version" | sed "s/Version: //"'), emit: versions_seqtk, topic: versions
```

The `eval()` qualifier runs a shell command *after* the script completes and captures its stdout. The `topic: versions` directive broadcasts the tuple into a shared channel that all processes in the pipeline contribute to — no explicit `ch_versions.mix(...)` chains needed.

---

## Hands-on Exercises

This session uses **two modules** as examples:

- `SEQTK_SEQ` — a complete, finished module you can study and run (**worked example**)
- `SEQTK_TRIMFQ` — a scaffold with gaps for you to fill in (**your exercise**)

Both modules wrap sub-commands of [`seqtk`](https://github.com/lh3/seqtk), a small and fast toolkit for processing FASTA/FASTQ files.

| Module | What it does | Input | Output |
|---|---|---|---|
| `SEQTK_SEQ` | Convert FASTQ → FASTA (and more) | FASTQ | FASTA.gz |
| `SEQTK_TRIMFQ` | Trim low-quality bases from reads | FASTQ | FASTQ.gz |

---

### Step 1 — Examine the directory structure

```bash
cd session16
tree modules/
```

You should see:
```
modules/
└── local/
    └── seqtk/
        ├── seq/          ← COMPLETE worked example
        │   ├── main.nf
        │   ├── meta.yml
        │   ├── environment.yml
        │   └── tests/
        │       ├── main.nf.test
        │       ├── main.nf.test.snap
        │       └── nextflow.config
        └── trimfq/       ← SCAFFOLD (your exercise)
            ├── main.nf
            ├── meta.yml
            ├── environment.yml
            └── tests/
                ├── main.nf.test
                └── nextflow.config
```

---

### Step 2 — Read the complete SEQTK_SEQ module

Open `modules/local/seqtk/seq/main.nf` and read every line. As you read, notice:

1. **Line 1–3:** `tag`, `label`, and the two `container` lines. The tag uses `$meta.id` for execution log tracing.
2. **The container block:** Singularity and Docker/Quay.io URLs are specified together in a ternary expression.
3. **input block:** A single `tuple val(meta), path(reads)` — the standard nf-core input shape.
4. **output block — `emit: fasta`:** Returns `[meta, *.fasta.gz]` as a tuple.
5. **output block — `emit: versions_seqtk, topic: versions`:** This is the 2026 topic channel pattern. No file is written.
6. **script block:** Two local `def` variables are defined *before* the heredoc. This is required — `${meta.id}` inside a heredoc triggers Bash glob substitution.
7. **stub block:** Creates an empty gzip file using `echo "" | gzip`. Note it defines the same `def` variables as the script block.

---

### Step 3 — Run the test pipeline with the completed module

The test pipeline at `main.nf` reads a samplesheet and runs SEQTK_SEQ on each sample.

First, look at the test data:
```bash
cat test_data/sample1.fastq
cat assets/samplesheet.csv
```

Now run the pipeline using conda (seqtk is in the environment.yml):
```bash
nextflow run main.nf -profile conda
```

You should see output like:
```
✓ sample1: sample1.fasta.gz
✓ sample2: sample2.fasta.gz
✓ sample3: sample3.fasta.gz
```

Check the results:
```bash
ls results/seqtk/seq/
zcat results/seqtk/seq/sample1.fasta.gz | head -4
```

You should see the FASTQ reads converted to FASTA format (no quality scores, `>` headers instead of `@`).

---

### Step 4 — Run the stub test for SEQTK_SEQ

nf-test lets you test module structure without running real tools:

```bash
cd modules/local/seqtk/seq
nf-test test tests/main.nf.test --profile conda
```

You should see:
```
✓ seqtk seq - fastq single-end - stub (1.2s)

SUCCESS: 1 tests, 1 passed, 0 failed
```

The `tests/main.nf.test.snap` file holds the snapshot of the expected output. If you look inside it, you'll see the md5 checksum of the stub gzip file and the version string captured by `eval()`.

> **Note on the snapshot:** The `.snap` file in this session was generated with your Nextflow/nf-test versions. If your environment differs, regenerate it:
> ```bash
> nf-test test tests/main.nf.test --update-snapshot --profile conda
> ```

---

## Exercises

### Basic — Fill in the SEQTK_TRIMFQ `main.nf`

Open `modules/local/seqtk/trimfq/main.nf`. You will see `# TODO` markers where content needs to be added.

The `seqtk trimfq` command trims low-quality bases. Basic usage:
```bash
seqtk trimfq [options] input.fastq | gzip > output.fastq.gz
```

Fill in:
1. The `tag` directive
2. The `label` directive (use `process_single`)
3. The container URLs (same seqtk image as `seq`)
4. The input block (same shape as SEQTK_SEQ: `tuple val(meta), path(reads)`)
5. The output block — emit `*.fastq.gz` as `trimmed` and add the topic channel version output
6. The `when` block (copy it exactly from SEQTK_SEQ — it never changes)
7. The script block with `def args` and `def prefix` before the heredoc
8. The stub block

When done, test your module by adding a test to `tests/main.nf.test` that runs with stub mode.

> **Hint:** The seqtk trimfq command writes to stdout, so you need to pipe to gzip:
> ```bash
> seqtk trimfq $args $reads | gzip --no-name > ${prefix}.fastq.gz
> ```

---

### Intermediate — Complete the `meta.yml` for SEQTK_TRIMFQ

Open `modules/local/seqtk/trimfq/meta.yml`. Fill in all `# TODO` sections:

1. **`description:`** Describe what seqtk trimfq does in one sentence
2. **`keywords:`** Add relevant terms (e.g., `trimming`, `quality`, `fastq`)
3. **`tools:`** Fill in seqtk's homepage (`https://github.com/lh3/seqtk`) and the `identifier: biotools:seqtk` line
4. **`input:`** Document the `meta` map and the `reads` file with proper EDAM ontology:
   - FASTQ data: `http://edamontology.org/data_2044`
   - FASTQ format: `http://edamontology.org/format_1930`
5. **`output:`** Document the `trimmed` output channel and the `versions_seqtk` topic output
   - FASTQ format for output: `http://edamontology.org/format_1930`
6. **`authors:`** Add your GitHub handle (e.g., `- "@yourusername"`)

Also open `modules/local/seqtk/trimfq/environment.yml` and fill in:
- The correct conda channels (order matters)
- The seqtk dependency with channel and version pinned to `1.4`

> **EDAM tip:** EDAM URLs follow the pattern `http://edamontology.org/format_XXXX` for file formats and `http://edamontology.org/data_XXXX` for data types. You can search the registry at https://edamontology.org

---

### Challenge — Write nf-test tests for SEQTK_TRIMFQ and run lint

**Part A — nf-test:**

Open `modules/local/seqtk/trimfq/tests/main.nf.test`. Add two tests:

1. A **stub test** that runs `SEQTK_TRIMFQ` with `options "-stub"` and asserts:
   - `process.success` is true
   - The snapshot matches (`assert snapshot(process.out).match()`)

2. A **real run test** (if you have Docker/Singularity available) using one of the test FASTQ files from `test_data/`.

For the stub test, the input data can point to `test_data/sample1.fastq`:
```groovy
input[0] = [
    [ id: 'test', single_end: true ],
    file("${projectDir}/../../../../test_data/sample1.fastq", checkIfExists: true)
]
```

Generate the snapshot:
```bash
cd modules/local/seqtk/trimfq
nf-test test tests/main.nf.test --update-snapshot --profile conda
```

**Part B — lint:**

Run the linter on both modules:
```bash
# From the session16 directory
nf-core modules lint --dir . --module seqtk/seq
nf-core modules lint --dir . --module seqtk/trimfq
```

Fix any warnings you see. Common ones:
- Missing `identifier: biotools:` in meta.yml tools section
- Missing EDAM ontology URL on a file input/output
- Stub block missing a `touch` for an output channel

> **Note:** `nf-core modules lint` expects the standard nf-core repo layout. When running against a local module outside the nf-core/modules repo, use `--dir .` to point it at the current directory.

---

## Debugging Tips

**1. `Error: Process 'SEQTK_SEQ' terminated with an error exit status (127)`**

Exit code 127 = command not found. The tool is not in your PATH. Make sure you are running with `-profile conda` or `-profile docker`, and that Wave/containers are enabled in your config.

**2. `NullPointerException` in the output block referencing `${meta.id}`**

This is the heredoc glob substitution bug. Double-check that you have `def prefix = task.ext.prefix ?: "${meta.id}"` *before* the triple-quoted block and that you are using `${prefix}` (not `${meta.id}`) inside the heredoc.

**3. `nf-test` snapshot mismatch after changing the stub block**

If you changed what the stub block creates, the old snapshot is stale. Run:
```bash
nf-test test tests/main.nf.test --update-snapshot
```
Then review the diff in the `.snap` file and commit it.

**4. `eval()` output captures nothing / version is blank**

The command inside `eval()` runs in the work directory after the script. If the tool is not on PATH in that environment, `eval()` returns empty. Test the version command manually inside a container:
```bash
docker run quay.io/biocontainers/seqtk:1.4--he4a0461_2 seqtk 2>&1 | grep "^Version"
```

**5. `nf-core modules lint` reports "meta.yml does not match expected schema"**

This usually means a YAML formatting issue — often wrong indentation or a missing `- -` prefix on a tuple channel element. Compare your `meta.yml` against the SEQTK_SEQ `meta.yml` worked example line-by-line.

---

## Key Takeaways

An nf-core module is a self-contained six-file package that wraps one tool (or one sub-command) and follows strict conventions so any pipeline can install and use it with `nf-core modules install`. The most important 2026 change is the topic channel version output: instead of writing a `versions.yml` file, modules now use `eval()` to capture a version string and broadcast it with `topic: versions`, letting the pipeline collect versions passively without any explicit channel wiring. Stub blocks are mandatory and must create every expected output file so `nf-test -stub` can validate module structure without actually running the tool.
