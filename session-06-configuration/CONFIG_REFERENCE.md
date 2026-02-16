# Nextflow Configuration Reference Card — Session 6

Quick reference for common configuration directives and patterns.

## Configuration Scopes

### params
```groovy
params {
    input = "data/samples.csv"
    outdir = "results"
    max_cpus = 16
    max_memory = '128.GB'
}
```

### process
```groovy
process {
    executor = 'local'
    cpus = 1
    memory = '2.GB'
    time = '1.h'
    container = 'ubuntu:22.04'
}
```

### docker
```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
    fixOwnership = true
    temp = 'auto'
}
```

### singularity
```groovy
singularity {
    enabled = true
    autoMounts = true
    cacheDir = '/path/to/cache'
}
```

### executor
```groovy
executor {
    name = 'slurm'
    queueSize = 50
    submitRateLimit = '10 sec'
}
```

---

## Process Directives

### Resource Allocation
```groovy
process MYPROCESS {
    cpus 4
    memory '8.GB'
    time '2.h'
    disk '100.GB'
}
```

### Container
```groovy
process MYPROCESS {
    container 'biocontainers/fastqc:0.11.9'
}
```

### Labels
```groovy
process MYPROCESS {
    label 'process_high'
    label 'error_retry'
}
```

### Error Handling
```groovy
process MYPROCESS {
    errorStrategy 'retry'
    maxRetries 3
    maxErrors 5
}
```

### Publishing
```groovy
process MYPROCESS {
    publishDir params.outdir, mode: 'copy', pattern: '*.{txt,csv}'
}
```

### Queue/Partition
```groovy
process MYPROCESS {
    queue 'general'
    clusterOptions '--account=myproject --qos=normal'
}
```

---

## Process Selectors

### withName
```groovy
process {
    withName: FASTQC {
        cpus = 2
        memory = '4.GB'
    }
    
    // Multiple processes
    withName: 'FASTQC|MULTIQC' {
        cpus = 2
    }
    
    // Pattern matching
    withName: 'ALIGN_.*' {
        cpus = 8
    }
}
```

### withLabel
```groovy
process {
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
}
```

---

## Profile Patterns

### Basic Profile
```groovy
profiles {
    standard {
        process.executor = 'local'
    }
}
```

### Docker Profile
```groovy
profiles {
    docker {
        docker.enabled = true
        docker.runOptions = '-u $(id -u):$(id -g)'
        process.container = 'ubuntu:22.04'
    }
}
```

### HPC Profile
```groovy
profiles {
    slurm {
        process {
            executor = 'slurm'
            queue = 'general'
            clusterOptions = '--account=myproject'
            
            withLabel: process_high {
                cpus = 16
                memory = '64.GB'
                time = '24.h'
                queue = 'bigmem'
            }
        }
    }
}
```

### Test Profile
```groovy
profiles {
    test {
        params {
            input = 'data/test_samples.csv'
            max_cpus = 2
            max_memory = '6.GB'
        }
    }
}
```

---

## Resource Limits (New in 24.04)

```groovy
resourceLimits {
    cpus = 8
    memory = '32.GB'
    time = '12.h'
}
```

**Effect:** Caps all process resource requests to these maximums.

---

## Executor Configuration

### Local
```groovy
process.executor = 'local'
```

### SLURM
```groovy
process {
    executor = 'slurm'
    queue = 'general'
    clusterOptions = '--account=myproject --partition=standard'
}

executor {
    queueSize = 50
    submitRateLimit = '10 sec'
}
```

### LSF
```groovy
process {
    executor = 'lsf'
    queue = 'normal'
    clusterOptions = '-P myproject'
}
```

### PBS/Torque
```groovy
process {
    executor = 'pbs'
    queue = 'batch'
}
```

### SGE
```groovy
process {
    executor = 'sge'
    penv = 'smp'
    queue = 'all.q'
}
```

### AWS Batch
```groovy
process {
    executor = 'awsbatch'
    queue = 'my-batch-queue'
    container = 'my-ecr-image:tag'
}

aws {
    region = 'us-east-1'
    batch {
        cliPath = '/usr/local/bin/aws'
    }
}
```

---

## Memory/Time/Disk Units

### Memory
```groovy
memory = '1.GB'   // Gigabytes
memory = '512.MB' // Megabytes
memory = '2.TB'   // Terabytes
memory = '1024'   // Bytes (avoid this, always specify units)
```

### Time
```groovy
time = '1.h'      // Hours
time = '30.m'     // Minutes
time = '90.s'     // Seconds
time = '2.d'      // Days
```

### Disk
```groovy
disk = '100.GB'
disk = '1.TB'
```

---

## Common Patterns

### Profile Inheritance
```groovy
profiles {
    base {
        process.cpus = 1
        process.memory = '2.GB'
    }
    
    docker {
        includeConfig 'base'
        docker.enabled = true
    }
}
```

### Conditional Configuration
```groovy
if (params.use_gpu) {
    process.containerOptions = '--gpus all'
}
```

### Dynamic Resource Allocation
```groovy
process MYPROCESS {
    memory = { 4.GB * task.attempt }
    time = { 2.h * task.attempt }
    errorStrategy = 'retry'
    maxRetries = 3
}
```

### Per-Process Container
```groovy
process {
    withName: FASTQC {
        container = 'biocontainers/fastqc:0.11.9'
    }
    withName: MULTIQC {
        container = 'ewels/multiqc:1.11'
    }
}
```

---

## Environment Variables

### In Configuration
```groovy
env {
    JAVA_OPTS = '-Xmx4g'
    TMPDIR = '/scratch'
}

process.env.PATH = '/custom/bin:$PATH'
```

### In Process
```groovy
process MYPROCESS {
    env MY_VAR = 'value'
    
    script:
    """
    echo "MY_VAR is: $MY_VAR"
    """
}
```

---

## Manifest Section

```groovy
manifest {
    name = 'my-pipeline'
    author = 'Your Name'
    homePage = 'https://github.com/user/pipeline'
    description = 'Pipeline description'
    mainScript = 'main.nf'
    nextflowVersion = '>=25.04.0'
    version = '1.0.0'
}
```

---

## Reporting

```groovy
report {
    enabled = true
    file = 'execution_report.html'
}

timeline {
    enabled = true
    file = 'execution_timeline.html'
}

dag {
    enabled = true
    file = 'pipeline_dag.png'
}

trace {
    enabled = true
    file = 'execution_trace.txt'
    fields = 'task_id,hash,name,status,exit,realtime,cpus,memory'
}
```

---

## CLI Usage

### Running with Profiles
```bash
nextflow run workflow.nf -profile docker
nextflow run workflow.nf -profile docker,test
```

### Overriding Parameters
```bash
nextflow run workflow.nf --input data.csv --outdir results
```

### Using Params File
```bash
nextflow run workflow.nf -params-file params.json
nextflow run workflow.nf -params-file params.yaml
```

### Using Custom Config
```bash
nextflow run workflow.nf -c custom.config
```

### Inspecting Configuration
```bash
nextflow config                           # Show resolved config
nextflow config -profile docker           # Show config for profile
nextflow config -show-profiles            # List available profiles
```

---

## Debugging Configuration

### Print Effective Configuration
```bash
nextflow config workflow.nf -profile docker
```

### Print Specific Section
```bash
nextflow config workflow.nf | grep -A 20 "process {"
```

### Validate Configuration
```bash
nextflow config workflow.nf -validate
```

### Check Profile Availability
```bash
nextflow config workflow.nf -show-profiles
```

---

## Common Gotchas

1. **Params require double-dash:** `--input` not `-input`
2. **Profiles use single-dash:** `-profile docker` not `--profile`
3. **Memory units are case-sensitive:** `GB` not `gb`
4. **Config hierarchy matters:** CLI > params-file > -c > nextflow.config
5. **Labels must match exactly:** `withLabel: process_high` requires `label 'process_high'`
6. **Container paths must be absolute** or use standard registries
7. **Process selectors are case-sensitive**
8. **Time format:** Use `.h`, `.m`, `.s`, not `h`, `m`, `s`

---

## Best Practices

1. ✅ Use profiles for different environments
2. ✅ Use labels for resource classes
3. ✅ Define sensible defaults in config
4. ✅ Allow CLI override for flexibility
5. ✅ Document your profiles in README
6. ✅ Use `resourceLimits` for development
7. ✅ Keep executor-specific config in profiles
8. ✅ Use `withLabel` for classes, `withName` for specific overrides
9. ✅ Test your config with `-preview` before running
10. ✅ Version your config files in git

---

This reference card covers the most common configuration patterns for Session 6 and beyond.
