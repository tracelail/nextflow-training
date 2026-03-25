# Session 17 — Input Validation with nf-schema

## Objectives

By the end of this session you will be able to:

- Declare and configure the **nf-schema plugin** (v2.6.1) in `nextflow.config`
- Understand how **two-phase validation** works: parameters first, samplesheet contents second
- Read and write a **`nextflow_schema.json`** file using JSON Schema Draft 2020-12 syntax, including the `$defs`/`allOf` grouping pattern
- Read and write a **samplesheet schema** (`assets/schema_input.json`) that validates CSV column values and maps fields into meta maps
- Use **`samplesheetToList()`** to convert a validated samplesheet into a Nextflow channel
- Trigger intentional validation failures to understand what error messages look like

---

## Prerequisites

- Sessions 1–16 completed
- `nf-core` conda environment active (`conda activate nf-core`)
- Nextflow v25.04+ installed (check: `nextflow -version`)
- nf-core tools v3.5+ installed (check: `nf-core --version`)

---

## Concepts

### Why validation matters

Without validation, a pipeline fails deep into execution — hours later, buried in process logs — because a typo in a filename or an invalid parameter value caused a cryptic Bash error. With nf-schema, the pipeline **stops before the first process** and prints a clear, human-readable error explaining exactly what is wrong.

### The nf-schema plugin

**nf-schema** is a Nextflow plugin (not a built-in feature) that must be explicitly loaded. It provides:

- `validateParameters()` — checks all pipeline parameters
- `samplesheetToList()` — validates and converts a samplesheet file into a Groovy List
- `paramsSummaryLog(workflow)` — returns a formatted string of parameters that differ from their defaults

The plugin uses **JSON Schema** — a standard, language-agnostic format for describing and validating data. Nextflow uses it for two purposes: describing pipeline parameters (`nextflow_schema.json`) and describing samplesheet contents (`assets/schema_input.json`). Both files use **JSON Schema Draft 2020-12**.

> **2026 note:** nf-schema v2.x requires the `$defs` keyword (not `definitions`) and the `$schema` URL must reference `draft/2020-12`. Pipelines using the old nf-validation v1.x pattern with `definitions` or `Channel.fromSamplesheet()` need migration.

### Two-phase validation

When `validateParameters()` is called:

**Phase 1** — Every parameter in `params` is checked against `nextflow_schema.json`: type, format, pattern, enum, required, file existence. An invalid param halts execution immediately. Checks if the pipeline parameters themselves are valid.

**Phase 2** — If a parameter's definition in `nextflow_schema.json` includes a `"schema"` key (pointing to a samplesheet schema file), nf-schema reads the file at that parameter's path and validates its contents against that schema. For example, `params.input` points to a CSV; its definition includes `"schema": "assets/schema_input.json"`, so every row of the CSV is validated. Checks if the content of the input samplesheet are valid.

### The `$defs` + `allOf` pattern in `nextflow_schema.json`

Nextflow parameters are a flat namespace (`params.input`, `params.outdir`). But good documentation groups them logically ("Input options", "Processing options"). JSON Schema's `$defs` provides a way to define named object groups, and `allOf` pulls them all into the top-level validation. This means the schema validates a flat object while appearing grouped in documentation UIs.

### The `meta` key in samplesheet schemas

The samplesheet schema uses a non-standard `"meta"` key on individual properties. Any field with `"meta": ["fieldname"]` gets placed into a Groovy Map rather than being a standalone channel element. Multiple `meta` fields are merged into a single map — the **meta map** from Session 8.

```
CSV row:    sample1, data/samples/sample1.txt, tumor, 1
           ^------^  ^--------------------^  ^---^  ^
           meta.id   separate path element   meta.condition  meta.replicate
```

The resulting channel element is:
```
[ [id: "sample1", condition: "tumor", replicate: 1],
  /abs/path/to/data/samples/sample1.txt ]
```

---

## Directory structure

```
session17/
├── main.nf                        ← entry workflow with validation calls
├── nextflow.config                ← plugin declaration + params defaults
├── nextflow_schema.json           ← pipeline parameter schema
├── assets/
│   └── schema_input.json          ← samplesheet row schema
├── modules/
│   └── local/
│       ├── word_count.nf
│       └── summarize.nf
├── data/
│   ├── samplesheet.csv            ← valid samplesheet (use this first)
│   ├── samplesheet_bad.csv        ← intentionally broken (Exercise 1)
│   ├── samplesheet_missing.csv    ← missing required field (Exercise 1)
│   └── samples/
│       ├── sample1.txt … sample4.txt
└── solutions/
    ├── exercise2_schema_input.json
    └── exercise3_nextflow_schema.json
```

---

## Hands-on exercises

### Exercise 1 (Basic) — Run the pipeline and see validation in action

**Step 1.** Navigate into the session directory:

```bash
cd session17
```

**Step 2.** Ask the pipeline for help. Because `validation.help.enabled = true` in `nextflow.config`, nf-schema generates help text automatically from the schema:

```bash
nextflow run main.nf --help
```

You should see each parameter listed with its description, type, and default value, grouped under "Input/output options" and "Processing options". Parameters marked `hidden: true` are not shown.

Try `--helpFull` to see hidden parameters too:

```bash
nextflow run main.nf --helpFull
```

**Step 3.** Run the pipeline with the valid samplesheet:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results
```

Watch the output carefully. You should see:

```
Validation of pipeline parameters was successful!
-- Parameters summary log --
input  : data/samplesheet.csv
outdir : results
```

The lines `min_word_length`, `suffix`, and `condition_filter` do not appear in the summary because they were not overridden from their defaults.

**Step 4.** Now deliberately break things. Run with a parameter that violates the schema:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --min_word_length 99
```

You should see a validation error immediately — before any process runs — because `99` violates `"maximum": 20`.

**Step 5.** Try an enum violation:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --condition_filter UNKNOWN
```

**Step 6.** Now try the broken samplesheet. This tests Phase 2 — samplesheet content validation:

```bash
nextflow run main.nf \
    --input data/samplesheet_bad.csv \
    --outdir results
```

Look at the error carefully. nf-schema reports *which row*, *which column*, and *what rule failed*.

**Step 7.** Try the missing-field samplesheet:

```bash
nextflow run main.nf \
    --input data/samplesheet_missing.csv \
    --outdir results
```

**Step 8.** Run with a condition filter to process only tumor samples:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --condition_filter tumor
```

Only sample1 and sample3 should appear in the summary output.

> **Check your understanding:** Why does `--min_word_length 99` fail before any process runs, even though WORD_COUNT is the only process that uses it? (Answer: `validateParameters()` is the first statement in the `workflow {}` block, so it runs before channel construction or process calls.)

---

### Exercise 2 (Intermediate) — Extend the samplesheet schema

Open `assets/schema_input.json` in your editor.

**Task A — Add `dependentRequired`.**

The concept: sometimes one optional field only makes sense if another field is also provided. `dependentRequired` enforces this at the object level (inside `"items"`).

Add an optional `paired_file` column to the schema. When `paired_file` is provided, `data_file` must also be present (it always is here, but the rule demonstrates the pattern). Add this block inside `"items"` alongside `"required"`:

```json
"dependentRequired": {
    "paired_file": ["data_file"]
}
```

Also add the property definition for `paired_file` inside `"properties"`:

```json
"paired_file": {
    "type": "string",
    "format": "file-path",
    "exists": true,
    "pattern": "^\\S+\\.txt$",
    "errorMessage": "paired_file must be an existing .txt file.",
    "meta": ["paired"]
}
```

**Task B — Enforce uniqueness across two columns.**

The current schema has `"uniqueEntries": ["sample"]` which prevents duplicate sample names. Change it to enforce uniqueness across the **combination** of `sample` AND `replicate` — meaning the same sample name can appear multiple times, but not with the same replicate number:

```json
"allOf": [
    {
        "uniqueEntries": ["sample", "replicate"]
    }
]
```

Create a test CSV to verify your uniqueness rule triggers:

```bash
cat > /tmp/dupe_test.csv << 'EOF'
sample,data_file,condition,replicate
sample1,data/samples/sample1.txt,tumor,1
sample1,data/samples/sample2.txt,normal,1
EOF

nextflow run main.nf \
    --input /tmp/dupe_test.csv \
    --outdir results
```

You should see a uniqueness validation error for the duplicate `sample1,1` combination.

Compare your schema against `solutions/exercise2_schema_input.json`.

---

### Exercise 3 (Challenge) — Add custom validation rules to the pipeline schema

Open `nextflow_schema.json`.

**Task A — Add `errorMessage` to existing properties.**

The default nf-schema error messages reference the schema rule that failed. Custom `errorMessage` fields replace them with plain English. Add `errorMessage` to `suffix` and `min_word_length`:

```json
"suffix": {
    "type": "string",
    "default": "counted",
    "pattern": "^[a-zA-Z0-9_-]+$",
    "errorMessage": "suffix may only contain letters, numbers, underscores, and hyphens.",
    ...
}
```

Test it:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --suffix 'bad value!'
```

The error message should now show your custom text.

**Task B — Add a hidden `email` parameter.**

Add a new parameter to the `processing_options` group. Hidden parameters don't appear in normal `--help` output but are still validated if provided:

```json
"email": {
    "type": "string",
    "format": "email",
    "description": "Email address for pipeline completion notification.",
    "fa_icon": "fas fa-envelope",
    "hidden": true,
    "help_text": "Set this to receive notification when the pipeline finishes."
}
```

Add `"email": null` to `params {}` in `nextflow.config` (or the schema will warn about an unrecognised parameter if someone tries to use it). Test the email format validation:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --email "not-an-email"
```

Then test with a valid email:

```bash
nextflow run main.nf \
    --input data/samplesheet.csv \
    --outdir results \
    --email "user@example.com"
```

**Task C — Explore `nf-core pipelines schema build`** (if you have a pipeline created from the nf-core template in a previous session).

The `nf-core pipelines schema build` command reads your `nextflow.config` params block, compares it to an existing `nextflow_schema.json`, and opens an interactive web editor for any params not yet in the schema. It does not touch the samplesheet schema.

```bash
# From inside an nf-core template pipeline directory:
nf-core pipelines schema build
```

This is the workflow nf-core developers use to keep the schema in sync after adding new parameters.

Compare your final schema against `solutions/exercise3_nextflow_schema.json`.

---

## Expected outputs

After a successful run of Exercise 1 Step 3, your `results/` directory contains:

```
results/
└── pipeline_summary_counted.txt
```

With content like:

```
=== Pipeline Summary ===
Generated: Mon Mar 23 ...
Suffix: counted

--- sample1.counts.txt ---
Sample: sample1
Condition: tumor
Replicate: 1
---
Total words: 42
Words >= 3 chars: 28

--- sample2.counts.txt ---
...
```

After the tumor-only run (Step 8), the summary contains only sample1 and sample3.

---

## Debugging tips

**"Plugin 'nf-schema@2.6.1' not found"**
Nextflow downloads plugins from the Nextflow plugin registry on first use. If you are offline or behind a firewall, the download may fail. Run `nextflow plugin install nf-schema@2.6.1` once while online to cache it.

**"ERROR ~ Validation of pipeline parameters failed"**
This is working as intended. Read the error carefully — it tells you the parameter name, the value you provided, and the rule that failed. Fix the value and re-run.

**"Unrecognised parameter" warning for a param you know you defined**
The param must be present in `nextflow_schema.json` as well as in `nextflow.config`. If it is only in `nextflow.config`, nf-schema warns. Add it to the schema, or add it to `validation.logging.unrecognisedParams = "skip"` to silence the warning during development.

**"`samplesheetToList()` cannot find file"**
The path you pass to `samplesheetToList()` for the schema must be absolute or relative to the launch directory. Using `"${projectDir}/assets/schema_input.json"` is safest. If you launch from a parent directory, `projectDir` correctly points to where `main.nf` lives.

**"Error on line N of samplesheet" with a row number off by one**
nf-schema counts from 0 for the items array, but error messages use 1-based row numbers that include the header. Row 1 in the error = the first data row.

**Schema changes don't seem to take effect**
JSON Schema files are read at runtime, not cached by Nextflow's `-resume` mechanism. If you edit the schema, re-running (with or without `-resume`) will use the updated rules. You do not need to clear the work directory.

---

## Key takeaways

The nf-schema plugin enforces a clear contract between pipeline authors and users: parameters and samplesheet contents are fully validated before the first process runs, producing clear human-readable errors at the right moment. The two-schema design separates pipeline-level concerns (`nextflow_schema.json` with `$defs`/`allOf` grouping) from samplesheet-level concerns (`assets/schema_input.json` with the `meta` key controlling channel structure). The `samplesheetToList()` function bridges validation and channel construction — it both checks the file and returns the structured data that populates your input channel.

---

## Reference links

- nf-schema docs: https://nextflow-io.github.io/nf-schema/latest/
- training.nextflow.io Hello nf-core Part 5: https://training.nextflow.io/2.8.1/hello_nf-core/05_input_validation/
- JSON Schema Draft 2020-12: https://json-schema.org/draft/2020-12
- nf-schema migration guide (from nf-validation): https://nextflow-io.github.io/nf-schema/latest/migration_guide/
