# Session 6 — Quick Start Guide

This is a condensed reference for quickly running through Session 6. For detailed explanations, see README.md.

## Setup
```bash
cd ~/nextflow-training
tar -xzf session-06-configuration.tar.gz
cd session-06-configuration
```

## Exercise 1: Basic Configuration (5 minutes)

```bash
# Run with defaults
nextflow run simple_config.nf

# Override via CLI
nextflow run simple_config.nf --greeting "Bonjour" --name "Claude" --repetitions 5

# Override via params file
nextflow run simple_config.nf -params-file params.yaml

# Test precedence (CLI wins)
nextflow run simple_config.nf -params-file params.yaml --name "Jimmy"

# Can also use JSON
nextflow run simple_config.nf -params-file params.json
```

**Check outputs:** Look in `results/`, `spanish_results/`, and `french_results/` directories.

---

## Exercise 2: Multi-Profile Configuration (10 minutes)

```bash
# Local execution (no containers)
nextflow run analysis_pipeline.nf -profile local

# Docker execution
nextflow run analysis_pipeline.nf -profile docker

# Singularity execution (if available)
nextflow run analysis_pipeline.nf -profile singularity

# Laptop profile with resource limits
nextflow run analysis_pipeline.nf -profile laptop

# Inspect resolved config
nextflow config -profile docker

# Compare profiles
nextflow config -profile local | grep -A 5 "withLabel"
nextflow config -profile laptop | grep -A 5 "withLabel"
```

**Check outputs:** Examine `results/sample1_report.txt` to see CPU/memory allocations for each profile.

---

## Exercise 3: SLURM and Advanced Selectors (15 minutes)

```bash
# Preview SLURM execution (doesn't actually run)
nextflow run analysis_pipeline.nf -profile slurm -preview

# Use custom config override
nextflow run analysis_pipeline.nf -profile slurm -c hpc_overrides.config -preview

# Inspect SLURM configuration
nextflow config -profile slurm | grep -A 30 "process {"

# Test resource allocation with different profiles
nextflow run resource_test.nf -profile local
nextflow run resource_test.nf -profile laptop
nextflow run resource_test.nf -profile docker

# View resolved config for specific process
nextflow config -profile slurm | grep -A 5 "withName:SUMMARIZE"
```

**Check outputs:** Console output shows resource allocations; work directories contain `.command.sh` with actual commands.

---

## Useful Commands

### Inspect Configuration
```bash
# View resolved config for a profile
nextflow config -profile <profile_name>

# Show all available profiles
nextflow config -show-profiles

# View specific parameter
nextflow config | grep params

# View process configuration
nextflow config | grep -A 20 "process {"
```

### Debugging
```bash
# Check what was executed
nextflow log

# Find work directory for a specific process
nextflow log -f 'process,hash,name,status'

# Generate execution report
nextflow run <workflow> -with-report report.html

# Generate execution timeline
nextflow run <workflow> -with-timeline timeline.html

# Generate DAG visualization
nextflow run <workflow> -with-dag flowchart.png
```

### Work Directory Inspection
```bash
# Navigate to work dir
cd work/xx/yyy...

# View executed command
cat .command.sh

# Check stdout
cat .command.log

# Check stderr
cat .command.err

# Check exit code
cat .exitcode
```

---

## Profile Comparison Cheat Sheet

| Profile | Container | Executor | Best For |
|---------|-----------|----------|----------|
| `local` | None | local | Quick testing without containers |
| `docker` | Docker | local | Development with reproducible environments |
| `singularity` | Singularity | local | HPC without root access |
| `laptop` | Docker | local | Resource-constrained development |
| `slurm` | None | slurm | HPC cluster execution |

---

## Configuration Hierarchy (Priority Order)

1. **CLI parameters** `--param value` (highest)
2. **Params file** `-params-file params.json`
3. **Custom config** `-c custom.config`
4. **nextflow.config** (local directory)
5. **nextflow.config** (home directory)
6. **Script defaults** (lowest)

---

## Common Selectors

```groovy
// Apply to specific process by name
process {
    withName: FASTQC {
        cpus = 4
    }
}

// Apply to multiple processes with same label
process {
    withLabel: process_high {
        cpus = 8
        memory = '32.GB'
    }
}

// Multiple selectors
process {
    withName: 'FASTQC|MULTIQC' {
        cpus = 2
    }
}
```

---

## Resource Limits Example

```groovy
profiles {
    laptop {
        resourceLimits {
            cpus = 4
            memory = '8.GB'
            time = '2.h'
        }
    }
}
```

This caps ALL processes to these maximums, preventing resource over-allocation.

---

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Profile not found | Check spelling in `nextflow.config` |
| Params not working | Use `--param` (double-dash) not `-param` |
| Container not used | Check Docker/Singularity is running |
| Config not applied | Verify you're in correct directory |
| Resource limits ignored | `resourceLimits` caps requests, check logs |

---

## Expected Runtime

- Exercise 1: ~5 minutes
- Exercise 2: ~10 minutes  
- Exercise 3: ~15 minutes
- **Total: ~30 minutes** (plus exploration time)

---

## Success Checklist

- [ ] Ran pipeline with default parameters
- [ ] Overrode parameters via CLI
- [ ] Overrode parameters via params file
- [ ] Tested configuration precedence
- [ ] Ran pipeline with multiple profiles
- [ ] Inspected resolved configuration with `nextflow config`
- [ ] Used `withLabel` and `withName` selectors
- [ ] Configured `resourceLimits`
- [ ] Explored work directories
- [ ] Generated execution report

---

## Next Steps

Proceed to **Session 7: Groovy Essentials** to learn the scripting patterns that make Nextflow pipelines powerful and maintainable.

For detailed explanations of any concept, refer to the main **README.md** file.
