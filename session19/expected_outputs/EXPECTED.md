# Session 19 — Expected Outputs

## Exercise 1: Workflow output block

### Console output (abridged)
```
N E X T F L O W  ~  version 25.10.4

executor >  local (7)
[xx/xxxxxx] TRIM (sampleA) | 1 of 3 ✔
[xx/xxxxxx] TRIM (sampleB) | 2 of 3 ✔
[xx/xxxxxx] TRIM (sampleC) | 3 of 3 ✔
[xx/xxxxxx] COUNT (sampleA) | 1 of 3 ✔
[xx/xxxxxx] COUNT (sampleB) | 2 of 3 ✔
[xx/xxxxxx] COUNT (sampleC) | 3 of 3 ✔
[xx/xxxxxx] SUMMARISE       | 1 of 1 ✔
```

### Output directory structure
```
results/
├── trimmed/
│   ├── sampleA.trimmed.txt
│   ├── sampleB.trimmed.txt
│   └── sampleC.trimmed.txt
├── counts/
│   ├── sampleA.counts.txt
│   ├── sampleB.counts.txt
│   └── sampleC.counts.txt
└── pipeline_report.txt
```

### results/pipeline_report.txt
```
=== Pipeline Summary ===
Samples processed: 3

  sampleA: 21 words
  sampleB: 18 words
  sampleC: 18 words
```

### After switching to symlink mode
```bash
ls -la results/trimmed/
lrwxr-xr-x  sampleA.trimmed.txt -> /path/to/work/.../sampleA.trimmed.txt
lrwxr-xr-x  sampleB.trimmed.txt -> /path/to/work/.../sampleB.trimmed.txt
lrwxr-xr-x  sampleC.trimmed.txt -> /path/to/work/.../sampleC.trimmed.txt
```

---

## Exercise 2: Data lineage

### nextflow lineage list output
```
LID                                    UPDATED                  NAME             STATUS
lid://a1b2c3d4e5f6...                  2026-03-15 10:23:44      nf-run-xyz       COMPLETED
```

### nextflow lineage view lid://<LID> (abridged JSON)
```json
{
  "type": "WorkflowRun",
  "id": "lid://a1b2c3d4e5f6...",
  "runName": "nf-run-xyz",
  "sessionId": "...",
  "status": "COMPLETED",
  "scriptFiles": ["lid://.../.../ex2_lineage.nf"],
  "parameters": { "input_dir": "/path/to/data" },
  "tasks": ["lid://.../TRIM", "lid://.../COUNT", "lid://.../SUMMARISE"]
}
```

### nextflow lineage view lid://<LID>/results/counts/sampleA.counts.txt (abridged)
```json
{
  "type": "FileOutput",
  "path": "/absolute/path/results/counts/sampleA.counts.txt",
  "checksum": "sha256:abc123...",
  "source": "lid://.../COUNT",
  "size": 3,
  "labels": ["counts"]
}
```

---

## Exercise 3: Topic channels

### Console output (no change in task count — the mechanism is transparent)
```
executor >  local (7)
[xx/xxxxxx] TRIM (sampleA) | 1 of 3 ✔
[xx/xxxxxx] TRIM (sampleB) | 2 of 3 ✔
[xx/xxxxxx] TRIM (sampleC) | 3 of 3 ✔
[xx/xxxxxx] COUNT (sampleA) | 1 of 3 ✔
[xx/xxxxxx] COUNT (sampleB) | 2 of 3 ✔
[xx/xxxxxx] COUNT (sampleC) | 3 of 3 ✔
[xx/xxxxxx] SUMMARISE       | 1 of 1 ✔
```

### results/software_versions.txt (example — versions will vary by system)
```
COUNT | awk: GNU Awk 5.2.1, API 3.2
SUMMARISE | bash: 5.2.21
TRIM | bash: 5.2.21
```

Key things to check:
- The file exists at `results/software_versions.txt`
- There is one entry per tool (`.unique()` deduplicates repeated calls like TRIM running 3 times)
- No `versions.yml` files are in the work directory
- The workflow has no `ch_versions.mix(...)` lines

### Comparison: old vs new approach

| Old approach | New approach |
|---|---|
| `path "versions.yml", emit: versions` in every process | `eval('tool --version'), topic: versions` in every process |
| `cat <<-END_VERSIONS > versions.yml` heredoc in every script | No script changes needed |
| `ch_versions = ch_versions.mix(MODULE.out.versions.first())` for every module call | Nothing — automatic |
| Breaks if you forget one mix() call | Cannot be forgotten — topic is framework-level |

---

## Exercise 4: Handlers (bonus)

### Console output on success
```
╔══════════════════════════════════════════════════╗
║            Pipeline Complete                     ║
╠══════════════════════════════════════════════════╣
║  Status    : ✅  SUCCESS
║  Duration  : 3.2s
║  Completed : 2026-03-15T10:23:47.000-05:00
║  Launch dir: /path/to/session19
╚══════════════════════════════════════════════════╝
```

### Console output on error (nextflow run ex4_handlers.nf --trigger_error)
```
╔══════════════════════════════════════════════════╗
║            Pipeline ERROR                        ║
╠══════════════════════════════════════════════════╣
║  Error  : Process `MAYBE_FAIL` terminated with an error exit status (1)
║  Report : ...
╚══════════════════════════════════════════════════╝
```
