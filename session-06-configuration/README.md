# Session 6 — Configuration: Profiles, params, and resource management

## Learning Objectives

After completing this session, you will be able to:

- Understand and apply the 6-level configuration precedence hierarchy in Nextflow
- Create multi-profile configurations supporting different execution environments (local, Docker, Singularity, SLURM)
- Define and override pipeline parameters via CLI, params files (JSON/YAML), and nextflow.config
- Use process selectors (`withName`, `withLabel`) to apply resource directives to specific processes
- Configure the `resourceLimits` directive to cap resources for constrained environments
- Configure executor settings for different compute platforms

## Prerequisites

- **Completed sessions:** Sessions 1-5 (especially Session 5 on containers)
- **Required files:** You should have a working understanding of processes, workflows, and container directives
- **System requirements:** Docker or Singularity/Apptainer installed (from Session 5)

## Concepts

### Configuration Hierarchy

Nextflow uses a **6-level configuration precedence hierarchy** where settings from higher-priority sources override lower-priority ones:

1. **CLI parameters** (`--param value`) — highest priority
2. **Params file** (`-params-file params.json` or `-params-file params.yaml`)
3. **Config files specified with `-c`** (`-c custom.config`)
4. **`nextflow.config` in the workflow directory**
5. **`nextflow.config` in the home directory** (`$HOME/.nextflow/config`)
6. **Default values in the script** — lowest priority

This hierarchy allows you to define sensible defaults while providing flexible override mechanisms for different execution contexts.

### Parameters vs Configuration

Understanding the distinction between **params** and **configuration** is critical:

- **`params` scope**: Pipeline-specific parameters (input files, output directories, tool options). Accessed with `params.input`, `params.outdir`. Use double-dash on CLI: `--input data.csv`
- **Configuration scopes**: Execution settings (resources, containers, executors). Use single-dash on CLI: `-profile docker`

### Process Selectors

Process selectors allow you to apply configuration to specific processes without modifying the process definitions:

- **`withName:`** — targets a specific process by name (e.g., `withName: FASTQC`)
- **`withLabel:`** — targets all processes with a specific label (e.g., `withLabel: process_low`)

The `withLabel` pattern is the nf-core standard for resource management, defining classes like `process_low`, `process_medium`, `process_high`, `process_long`.

### Configuration Profiles

**Profiles** are named configuration presets that bundle related settings. Common profiles include:

- `docker` — enables Docker containers
- `singularity` — enables Singularity/Apptainer containers
- `test` — uses small test datasets
- `slurm` — configures SLURM executor for HPC
- `local` — single-machine execution with process executor

Profiles are activated with `-profile <name>` and can be combined: `-profile docker,test`.

### Resource Management

The `resourceLimits` directive (new in Nextflow 24.04) provides a simple way to cap resources globally:

```groovy
resourceLimits {
    cpus = 8
    memory = '32.GB'
    time = '24.h'
}
```

Any process requesting more than these limits will be automatically capped. This is especially useful for laptop development environments.

## Hands-On Exercises

### Setup

Create the session directory and navigate to it:

```bash
mkdir -p ~/nextflow-training/session-06-configuration
cd ~/nextflow-training/session-06-configuration
```

---

## Exercise 1: Basic Configuration and Parameter Override (BASIC)

**Objective:** Create a simple pipeline with parameters and learn to override them via CLI and params file.

### Step 1: Create the pipeline

Create `simple_config.nf` with the following content:

```groovy
#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// Default parameters
params.greeting = "Hello"
params.name = "World"
params.repetitions = 3
params.outdir = "results"

process GREET {
    publishDir params.outdir, mode: 'copy'
    
    output:
    path "greeting.txt"
    
    script:
    """
    for i in \$(seq 1 ${params.repetitions}); do
        echo "${params.greeting}, ${params.name}!"
    done > greeting.txt
    """
}

workflow {
    GREET()
}
```

### Step 2: Run with default parameters

```bash
nextflow run simple_config.nf
```

You should see:
- Execution log showing the GREET process completing
- `results/greeting.txt` containing "Hello, World!" repeated 3 times

### Step 3: Override parameters via CLI

Run with different parameters using double-dash `--`:

```bash
nextflow run simple_config.nf --greeting "Bonjour" --name "Claude" --repetitions 5
```

Check `results/greeting.txt` — it should now contain "Bonjour, Claude!" repeated 5 times.

### Step 4: Create a params file

Create `params.yaml`:

```yaml
greeting: "Hola"
name: "Nextflow"
repetitions: 2
outdir: "spanish_results"
```

Run with the params file:

```bash
nextflow run simple_config.nf -params-file params.yaml
```

Check `spanish_results/greeting.txt` — it should contain "Hola, Nextflow!" repeated 2 times.

### Step 5: Test precedence

Now combine both (CLI should override params file):

```bash
nextflow run simple_config.nf -params-file params.yaml --name "Jimmy"
```

The output should use "Hola, Jimmy!" (greeting from file, name from CLI).

---

## Exercise 2: Multi-Profile Configuration (INTERMEDIATE)

**Objective:** Create a `nextflow.config` file with multiple profiles for different execution environments.

### Step 1: Create the pipeline

Create `analysis_pipeline.nf`:

```groovy
#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.input = "data/samples.csv"
params.outdir = "results"

process ANALYZE {
    label 'process_low'
    container 'ubuntu:22.04'
    publishDir params.outdir, mode: 'copy'
    
    input:
    val sample_name
    
    output:
    path "${sample_name}_report.txt"
    
    script:
    """
    echo "Analyzing ${sample_name}" > ${sample_name}_report.txt
    echo "Memory: ${task.memory}" >> ${sample_name}_report.txt
    echo "CPUs: ${task.cpus}" >> ${sample_name}_report.txt
    echo "Container: ${task.container}" >> ${sample_name}_report.txt
    sleep 2
    echo "Analysis complete" >> ${sample_name}_report.txt
    """
}

process SUMMARIZE {
    label 'process_medium'
    container 'ubuntu:22.04'
    publishDir params.outdir, mode: 'copy'
    
    input:
    path reports
    
    output:
    path "summary.txt"
    
    script:
    """
    echo "Summary Report" > summary.txt
    echo "=============" >> summary.txt
    cat ${reports} >> summary.txt
    """
}

workflow {
    // Create sample channel
    samples_ch = channel.of('sample1', 'sample2', 'sample3')
    
    // Analyze each sample
    ANALYZE(samples_ch)
    
    // Collect and summarize
    SUMMARIZE(ANALYZE.out.collect())
}
```

### Step 2: Create nextflow.config

Create `nextflow.config`:

```groovy
// Default parameters
params {
    input = "data/samples.csv"
    outdir = "results"
}

// Default process settings
process {
    cpus = 1
    memory = '2.GB'
    time = '1.h'
}

// Profile definitions
profiles {
    // Local execution without containers
    local {
        process {
            executor = 'local'
            withLabel: process_low {
                cpus = 1
                memory = '2.GB'
            }
            withLabel: process_medium {
                cpus = 2
                memory = '4.GB'
            }
            withLabel: process_high {
                cpus = 4
                memory = '8.GB'
            }
        }
    }
    
    // Docker execution
    docker {
        docker.enabled = true
        docker.runOptions = '-u $(id -u):$(id -g)'
        
        process {
            withLabel: process_low {
                cpus = 1
                memory = '2.GB'
            }
            withLabel: process_medium {
                cpus = 2
                memory = '4.GB'
            }
            withLabel: process_high {
                cpus = 4
                memory = '8.GB'
            }
        }
    }
    
    // Singularity execution
    singularity {
        singularity.enabled = true
        singularity.autoMounts = true
        
        process {
            withLabel: process_low {
                cpus = 1
                memory = '2.GB'
            }
            withLabel: process_medium {
                cpus = 2
                memory = '4.GB'
            }
            withLabel: process_high {
                cpus = 4
                memory = '8.GB'
            }
        }
    }
    
    // Laptop development profile with resource limits
    laptop {
        docker.enabled = true
        
        resourceLimits {
            cpus = 4
            memory = '8.GB'
            time = '2.h'
        }
        
        process {
            withLabel: process_low {
                cpus = 1
                memory = '1.GB'
            }
            withLabel: process_medium {
                cpus = 2
                memory = '2.GB'
            }
            withLabel: process_high {
                cpus = 3
                memory = '4.GB'
            }
        }
    }
}
```

### Step 3: Test different profiles

Run with local profile:

```bash
nextflow run analysis_pipeline.nf -profile local
```

Run with Docker profile:

```bash
nextflow run analysis_pipeline.nf -profile docker
```

Run with laptop profile (resource-constrained):

```bash
nextflow run analysis_pipeline.nf -profile laptop
```

### Step 4: Inspect the outputs

Check `results/sample1_report.txt` to see the memory and CPU allocations for each profile.

---

## Exercise 3: SLURM Configuration and Advanced Selectors (CHALLENGE)

**Objective:** Configure a SLURM executor profile and use `withName` selectors for fine-grained control.

### Step 1: Add SLURM profile to nextflow.config

Add this profile to your existing `nextflow.config` (after the `laptop` profile):

```groovy
    // SLURM executor for HPC
    slurm {
        process {
            executor = 'slurm'
            queue = 'general'
            clusterOptions = '--account=myproject'
            
            withLabel: process_low {
                cpus = 2
                memory = '4.GB'
                time = '2.h'
            }
            withLabel: process_medium {
                cpus = 8
                memory = '16.GB'
                time = '8.h'
            }
            withLabel: process_high {
                cpus = 16
                memory = '64.GB'
                time = '24.h'
            }
            
            // Process-specific override
            withName: SUMMARIZE {
                cpus = 1
                memory = '2.GB'
                time = '30.m'
                queue = 'express'
            }
        }
    }
```

### Step 2: Create a config override file

Sometimes you need to override specific settings without modifying `nextflow.config`. Create `hpc_overrides.config`:

```groovy
process {
    withName: ANALYZE {
        cpus = 4
        memory = '8.GB'
        clusterOptions = '--account=special_project --qos=priority'
    }
}

params {
    outdir = 'hpc_results'
}
```

### Step 3: Test configuration precedence

Run with SLURM profile AND custom config (dry-run mode):

```bash
nextflow run analysis_pipeline.nf -profile slurm -c hpc_overrides.config -preview
```

**Note:** The `-preview` flag shows what would be executed without actually running it (useful on HPC systems where you may not want to submit test jobs).

### Step 4: Create a comprehensive resource allocation example

Create `resource_test.nf`:

```groovy
#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process TINY_TASK {
    label 'process_low'
    
    output:
    path "tiny.txt"
    
    script:
    """
    echo "Tiny: ${task.cpus} CPUs, ${task.memory}" > tiny.txt
    """
}

process MEDIUM_TASK {
    label 'process_medium'
    
    output:
    path "medium.txt"
    
    script:
    """
    echo "Medium: ${task.cpus} CPUs, ${task.memory}" > medium.txt
    """
}

process HUGE_TASK {
    label 'process_high'
    
    output:
    path "huge.txt"
    
    script:
    """
    echo "Huge: ${task.cpus} CPUs, ${task.memory}" > huge.txt
    """
}

process CUSTOM_TASK {
    // This process has no label, so only gets default settings
    
    output:
    path "custom.txt"
    
    script:
    """
    echo "Custom: ${task.cpus} CPUs, ${task.memory}" > custom.txt
    """
}

workflow {
    TINY_TASK()
    MEDIUM_TASK()
    HUGE_TASK()
    CUSTOM_TASK()
    
    TINY_TASK.out.view { "Tiny: ${it.text.trim()}" }
    MEDIUM_TASK.out.view { "Medium: ${it.text.trim()}" }
    HUGE_TASK.out.view { "Huge: ${it.text.trim()}" }
    CUSTOM_TASK.out.view { "Custom: ${it.text.trim()}" }
}
```

Run with laptop profile to see resource capping in action:

```bash
nextflow run resource_test.nf -profile laptop
```

Examine the output files to see how resources were allocated and capped.

---

## Debugging Tips

### 1. Configuration not being applied

**Problem:** You changed `nextflow.config` but nothing happened.

**Solution:** 
- Check that you're in the correct directory (config files are looked up relative to the workflow script)
- Use `nextflow config` to see the resolved configuration:
  ```bash
  nextflow config -profile docker
  ```
- Remember that params must use `params.` prefix in the config file

### 2. CLI parameters not working

**Problem:** Using `--param value` doesn't override your setting.

**Solution:**
- Params need double-dash `--` (not single dash `-`)
- Nextflow options use single dash: `-profile docker`
- Check spelling: `--outdir` not `--outDir` (case-sensitive)

### 3. Profile not found

**Problem:** `ERROR: Unknown profile: mydocker`

**Solution:**
- Profile names are defined in `nextflow.config` under `profiles { }`
- Profile names are case-sensitive
- Use comma-separated list for multiple profiles: `-profile docker,test`

### 4. Resource limits not being respected

**Problem:** Process is requesting more memory than your `resourceLimits` allows.

**Solution:**
- `resourceLimits` will cap the request, but you'll see a warning in logs
- This is expected behavior — the process will run with capped resources
- If a process truly needs more resources, you need to run on a bigger machine or adjust your limits

### 5. Configuration precedence confusion

**Problem:** Not sure which setting is being applied.

**Solution:**
- Use `nextflow config -profile <name> -show-profiles` to see resolved config
- Remember the hierarchy (CLI > params-file > -c > nextflow.config)
- Use `nextflow run -dump-channels` to debug channel contents
- Add `echo "CPUs: ${task.cpus}"` in your scripts to verify resource allocation

### 6. Docker/Singularity not being used despite profile

**Problem:** Container not being used even with `-profile docker`.

**Solution:**
- Check that Docker is running: `docker ps`
- For Singularity, check: `singularity --version`
- Ensure processes have `container` directive defined
- Check profile actually enables the container runtime:
  ```groovy
  docker.enabled = true  // in the docker profile
  ```

---

## Key Takeaways

1. **Configuration hierarchy matters:** CLI parameters override params files, which override nextflow.config. Use this deliberately — defaults in config, overrides on CLI.

2. **Labels are your friend:** Use `withLabel:` selectors for resource classes (`process_low`, `process_medium`, `process_high`) to maintain flexibility. This is the nf-core standard and makes your pipeline portable.

3. **Profiles enable portability:** A well-configured pipeline with profiles can run anywhere — your laptop, Docker, HPC, cloud — with just a profile flag. This is essential for reproducibility and collaboration.

---

## Expected Outputs

After completing all exercises, you should have:

- `results/` directory with greeting.txt from Exercise 1
- `spanish_results/` directory with Spanish greeting
- `results/` directory with sample reports and summary from Exercise 2
- `hpc_results/` (if you ran Exercise 3 overrides)
- Multiple work directories showing different resource allocations
- Understanding of how to inspect resolved configuration with `nextflow config`

---

## Next Steps

In **Session 7**, we'll dive into Groovy essentials that power Nextflow's scripting capabilities. You'll learn about data structures, closures with explicit parameters, and functional patterns that make Nextflow pipelines elegant and maintainable.

---

## Reference: Common Configuration Directives

| Directive | Scope | Description | Example |
|-----------|-------|-------------|---------|
| `cpus` | process | Number of CPUs | `cpus = 4` |
| `memory` | process | Memory allocation | `memory = '8.GB'` |
| `time` | process | Time limit | `time = '2.h'` |
| `queue` | process | Scheduler queue | `queue = 'general'` |
| `container` | process | Container image | `container = 'ubuntu:22.04'` |
| `executor` | process | Execution backend | `executor = 'slurm'` |
| `publishDir` | process | Output directory | `publishDir 'results', mode: 'copy'` |
| `label` | process | Resource class label | `label 'process_high'` |
| `resourceLimits` | global | Cap all resources | `resourceLimits { cpus = 8 }` |

---

## Additional Resources

- Official Nextflow configuration documentation: https://www.nextflow.io/docs/latest/config.html
- Configuration profiles: https://www.nextflow.io/docs/latest/config.html#config-profiles
- Process directives: https://www.nextflow.io/docs/latest/process.html#directives
- Executor configuration: https://www.nextflow.io/docs/latest/executor.html
