# Session 16 — Concepts Reference Card

## The six-file module structure

```
modules/local/<tool>/<subtool>/
├── main.nf              Process definition
├── meta.yml             Documentation + EDAM ontology
├── environment.yml      Conda dependency spec
└── tests/
    ├── main.nf.test     nf-test test definitions
    ├── main.nf.test.snap  Snapshot (auto-generated, committed to git)
    └── nextflow.config  Test-specific config (ext.args, etc.)
```

Naming rules:
- Directory path: always **lowercase** (`seqtk/seq/`)
- Process name: always **UPPERCASE** (`SEQTK_SEQ`)
- Single-command tool: `tool/` → `TOOL`
- Sub-command tool: `tool/subtool/` → `TOOL_SUBTOOL`

---

## Anatomy of a compliant main.nf

```nextflow
process TOOL_SUBTOOL {
    tag "$meta.id"           // ← always $meta.id — never change this
    label 'process_single'   // ← one of: process_single, _low, _medium, _high, _long

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tool:version' :
        'quay.io/biocontainers/tool:version' }"

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("*.ext"),   emit: result
    tuple val("${task.process}"), val('toolname'),
        eval('toolname --version 2>&1 | sed "s/.*v//"'),
        emit: versions_toolname, topic: versions

    when:
    task.ext.when == null || task.ext.when    // ← never change this either

    script:
    def args   = task.ext.args   ?: ''        // ← MUST be before the heredoc
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    toolname \\
        $args \\
        $input_file \\
        > ${prefix}.ext
    """

    stub:
    def args   = task.ext.args   ?: ''        // ← repeat def variables in stub
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.ext
    """
}
```

---

## Why `def` variables before the heredoc?

Inside a triple-quoted Bash heredoc, `${meta.id}` looks like a Bash variable
to the shell and triggers glob substitution. Nextflow does NOT interpolate it
before handing the script to Bash — the shell sees a literal `${meta.id}`.

**Broken** (glob substitution in Bash):
```nextflow
script:
"""
gzip -c $reads > ${meta.id}.fasta.gz    # ← Bash sees ${meta.id}, tries glob
"""
```

**Correct** (extract to local def first):
```nextflow
script:
def prefix = task.ext.prefix ?: "${meta.id}"  // ← Nextflow interpolates here
"""
gzip -c $reads > ${prefix}.fasta.gz    # ← Bash sees ${prefix}, which is fine
"""
```

The same rule applies to the `stub:` block — define the variables there too.

---

## The 2026 topic channel version pattern

**Why it changed:** The old `versions.yml` heredoc required every subworkflow
to explicitly mix version channels together:
```nextflow
// Old pattern — explicit channel mixing needed in every subworkflow
ch_versions = ch_versions.mix(FASTQC.out.versions.first())
ch_versions = ch_versions.mix(TRIMGALORE.out.versions.first())
ch_versions = ch_versions.mix(STAR_ALIGN.out.versions.first())
```
With 10+ modules, this became noisy boilerplate.

**New pattern — topic channels broadcast automatically:**
```nextflow
// In main.nf — this single line collects ALL module versions
channel.topic("versions")
```

No mixing. No `.first()`. Every module emits to the topic and the pipeline
reads from it at the end.

**The output block syntax:**
```nextflow
output:
tuple val("${task.process}"), val('toolname'),
    eval('toolname --version 2>&1 | grep version | sed "s/.*: //"'),
    emit: versions_toolname, topic: versions
```

The three elements of the tuple:
1. `val("${task.process}")` — the fully qualified process name, e.g. `PIPELINE:SUBWORKFLOW:FASTQC`
2. `val('toolname')` — the tool name as a plain string
3. `eval('...')` — runs a shell command AFTER the script completes, captures stdout

`topic: versions` is what broadcasts the tuple. Nextflow collects all topic
emissions transparently across all tasks.

**Status:** Introduced in nf-core/tools v3.5.0 (Nov 2025).
Mandatory in Q2 2026.

---

## stub: block rules

Every module must have a stub block. Run with:
```bash
nextflow run main.nf -stub
```

Rules:
1. Define the same `def` variables as the `script:` block
2. Create a file for every output channel with `touch` or `echo | gzip`
3. **Never** use `touch file.gz` — creates an invalid gzip that breaks nf-test
4. Use `echo "" | gzip --no-name > ${prefix}.ext.gz` for gzip outputs

```nextflow
stub:
def args   = task.ext.args   ?: ''
def prefix = task.ext.prefix ?: "${meta.id}"
"""
echo "" | gzip --no-name > ${prefix}.output.gz    # ← valid empty gzip
touch ${prefix}.index                             # ← touch is fine for non-gz
"""
```

---

## meta.yml channel-grouped format (July 2025)

Tuple channels use a **double dash** `- -` prefix. Single-value channels use
a single `-`.

```yaml
input:
  # Tuple channel: [meta, reads]
  - - meta:            # ← first "- " opens the channel, second opens the tuple element
        type: map
        description: Sample metadata map
    - reads:           # ← second element of the same tuple
        type: file
        pattern: "*.fastq.gz"
        ontologies:
          - edam: "http://edamontology.org/format_1930"

  # Single-value channel: just a boolean flag
  - sort:
      type: boolean
      description: Whether to sort output
```

EDAM ontology quick reference:

| Type | EDAM URL |
|------|----------|
| FASTQ | `http://edamontology.org/format_1930` |
| FASTA | `http://edamontology.org/format_1929` |
| BAM | `http://edamontology.org/format_2572` |
| VCF | `http://edamontology.org/format_3016` |
| BED | `http://edamontology.org/format_3003` |
| Sequence reads (data) | `http://edamontology.org/data_2044` |
| Sequence alignment (data) | `http://edamontology.org/data_1383` |

Search the full registry at: https://edamontology.org

---

## environment.yml rules

```yaml
channels:
  - conda-forge      # ← MUST come first
  - bioconda
dependencies:
  - "bioconda::package=1.2.3"    # ← channel::name=version, no build string
```

- No `name:` field (removed — broke Wave container caching)
- Pin to version, never to build hash
- Multi-tool: list one dependency per line

---

## nf-test anatomy

```groovy
nextflow_process {

    name "Test Process TOOL_SUBTOOL"
    script "../main.nf"
    process "TOOL_SUBTOOL"

    tag "modules"           // required
    tag "modules_nfcore"    // required
    tag "tool"              // required
    tag "tool/subtool"      // required

    test("description - stub") {
        options "-stub"

        when {
            process {
                """
                input[0] = [ [ id:'test' ], file("path/to/data", checkIfExists: true) ]
                """
            }
        }

        then {
            assertAll(
                { assert process.success },
                { assert snapshot(process.out).match() }
            )
        }
    }
}
```

Snapshot commands:
```bash
# First run — generates the .snap file
nf-test test tests/main.nf.test --update-snapshot

# Subsequent runs — compares against saved snapshot
nf-test test tests/main.nf.test

# After intentionally changing output — update and review diff
nf-test test tests/main.nf.test --update-snapshot
```

---

## ext.args and ext.prefix in modules.config

```nextflow
// conf/modules.config
process {
    withName: 'TOOL_SUBTOOL' {
        // Always use closures { } — without them, ext.args is evaluated
        // at parse time (before any data exists) and meta won't be accessible.
        ext.args   = { "--threads ${task.cpus}" }
        ext.prefix = { "${meta.id}.processed" }
        publishDir = [
            path: { "${params.outdir}/tool" },
            mode: 'copy'
        ]
    }
}
```

The module picks these up with:
```nextflow
def args   = task.ext.args   ?: ''
def prefix = task.ext.prefix ?: "${meta.id}"
```

The `?: ''` and `?: "${meta.id}"` are **Elvis operators** — they return the
right-hand side when the left is null. If `modules.config` does not set
`ext.args`, the module defaults to an empty string (no extra arguments).
