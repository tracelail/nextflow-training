# Session 5 — Containers: Reproducible Software Environments

## Learning Objectives

After completing this session, you will be able to:

- Configure and run Nextflow processes with **Docker** and **Singularity/Apptainer** containers
- Understand the `container` directive and container resolution mechanisms
- Switch between container runtimes using configuration profiles
- Work with **Biocontainers** registry images for bioinformatics tools
- Understand the modern **Seqera Containers** approach using `environment.yml`
- Configure container settings in `nextflow.config` for different execution environments

## Prerequisites

- Completed Sessions 1–4 (basic Nextflow processes, channels, workflows, and modules)
- Docker installed and running on your system, OR Singularity/Apptainer available
- Basic understanding of why software reproducibility matters in computational workflows

## Concepts

### Why Containers Matter

**Containers** solve the "works on my machine" problem by packaging software and all its dependencies into a portable, reproducible environment. In bioinformatics, where tools often have complex dependency chains (Python libraries, R packages, compiled binaries), containers ensure that:

1. **Your pipeline produces identical results** regardless of where it runs (your laptop, HPC cluster, cloud)
2. **Software versions are locked** — no more "it worked last month" issues
3. **Installation is trivial** — pull a container image instead of fighting with conda environments or compilation errors

Nextflow has first-class container support. When you specify a `container` directive in a process, Nextflow automatically:
- Pulls the image if it doesn't exist locally
- Mounts your work directory into the container
- Runs the process script inside the container
- Handles output files seamlessly

### Container Runtimes: Docker vs Singularity/Apptainer

**Docker** is the most popular container runtime, great for local development and cloud execution. However, many HPC clusters don't allow Docker for security reasons (it requires root privileges).

**Singularity** (now called **Apptainer** in its open-source form) is designed for HPC environments. It doesn't require root, can pull Docker images directly, and integrates well with shared filesystems and job schedulers like SLURM.

Nextflow treats Docker and Apptainer as separate configuration scopes, but can run the same Docker images with either runtime. You configure which runtime to use in `nextflow.config`:

```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'  // Run as current user, not root
}

apptainer {
    enabled = true
    autoMounts = true  // Automatically bind-mount necessary paths
}
```

### Modern Container Management: Seqera Containers

The traditional approach requires pipeline developers to build and publish container images manually. **Seqera Containers** (launched 2024) automates this:

1. Developer writes an `environment.yml` file listing conda packages
2. Seqera's infrastructure automatically builds a container image via **Wave**
3. The image is cached and reused across the community
4. No Docker registry management needed

This is now the **recommended approach for nf-core modules**. You'll see `environment.yml` files in every modern nf-core module.

### Finding Container Images

- **Biocontainers** ([https://biocontainers.pro](https://biocontainers.pro)) — pre-built containers for 10,000+ bioinformatics tools
- **DockerHub** — general container registry (use with caution, not all images are maintained)
- **quay.io** — alternative registry, heavily used by Biocontainers
- **Seqera Containers** — auto-built from conda recipes, used by nf-core

## Hands-On Exercises

We'll build three versions of the same pipeline to explore different container configurations:

1. **Basic**: Single process with a Docker container
2. **Intermediate**: Multi-profile config supporting Docker and Singularity
3. **Challenge**: Understanding Seqera Containers and `environment.yml`

### Setup: Check Your Container Runtime

Before starting, verify you have at least one container runtime available:

```bash
# Check Docker
docker --version
docker ps

# OR check Singularity/Apptainer
singularity --version
# OR
apptainer --version
```

If Docker isn't running, start it. If you don't have Docker but have Singularity/Apptainer, you can still complete all exercises by using the appropriate profile.

---

## Exercise 1: Basic — Your First Containerized Process

Let's start with a simple process that runs inside a container.

### Step 1: Create the workflow file

Create a file called `01_basic_container.nf`:

```nextflow
#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * A simple process that uses FastQC to check sequence quality
 */
process FASTQC_BASIC {
    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir 'results/fastqc', mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path("${sample_id}_fastqc.html")
    path("${sample_id}_fastqc.zip")

    script:
    """
    # Run FastQC
    # FastQC will automatically name outputs based on input filename
    fastqc ${reads}
    """

    workflow {
        // Create a channel with a sample
        samples_ch = channel.of(
            ['sample1', file('data/sample1.fastq')]
        )

        // Run the process
        FASTQC_BASIC(samples_ch)
    }
}

```

### Step 2: Create sample data

We need a tiny FASTQ file for testing:

```bash
mkdir -p data
cat > data/sample1.fastq << 'EOF'
@SEQ_ID_1
GATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT
+
!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65
@SEQ_ID_2
CGATTAAAGATAGAAATACACGATGCGAGCAATCAAATTTCATAACATCACCATGAGTTT
+
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@SEQ_ID_3
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
+
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
EOF
```

### Step 3: Create a configuration file

Create `nextflow.config`:

```groovy
// Enable Docker
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
}
```

### Step 4: Run the pipeline

```bash
nextflow run 01_basic_container.nf
```

### What You Should See

1. Nextflow will pull the Docker image (this may take a minute the first time)
2. The process executes inside the container
3. FastQC HTML and ZIP files appear in `results/fastqc/`
4. The work directory contains `.command.sh` showing the script that ran

**Key observation**: The `fastqc` command worked without installing FastQC on your system! It ran inside the container.

### Step 5: Inspect the work directory

```bash
# Find the work directory for the process
ls -la work/*/*

# Look at the command that was executed
cat work/*/*/.command.sh

# Check the container information
cat work/*/*/.command.run
```

You'll see that Nextflow automatically:
- Mounted your work directory into the container
- Set up environment variables
- Ran the script inside the containerized environment

---

## Exercise 2: Intermediate — Multi-Profile Container Configuration

Real pipelines need to run on different infrastructures. Let's create a flexible configuration that supports Docker locally and Singularity on HPC.

### Step 1: Create an enhanced workflow

Create `02_multiprofile_container.nf`:

```nextflow
#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Process using seqtk to subsample FASTQ files
 */
process SEQTK_SAMPLE {
    tag "$sample_id"
    container 'biocontainers/seqtk:v1.3-1-deb_cv1'

    input:
    tuple val(sample_id), path(reads)
    val(num_reads)

    output:
    tuple val(sample_id), path("${sample_id}_sampled.fastq"), emit: reads

    script:
    """
    seqtk sample -s 100 ${reads} ${num_reads} > ${sample_id}_sampled.fastq
    """
}

/*
 * Process using FastQC for quality control
 */
process FASTQC {
    tag "$sample_id"
    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir 'results/qc', mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*_fastqc.{html,zip}"), emit: reports

    script:
    """
    fastqc -q ${reads}
    """
}

/*
 * Process using MultiQC to aggregate reports
 */
process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0'

    publishDir 'results/multiqc', mode: 'copy'

    input:
    path(fastqc_files)

    output:
    path("multiqc_report.html")
    path("multiqc_data")

    script:
    """
    multiqc .
    """
}

workflow {
    // Create channel with multiple samples
    samples_ch = channel.fromPath('data/*.fastq')
        .map { file ->
            def sample_id = file.baseName
            [sample_id, file]
        }

    // Subsample reads
    SEQTK_SAMPLE(samples_ch, 50)

    // Run QC
    FASTQC(SEQTK_SAMPLE.out.reads)

    // Aggregate with MultiQC
    MULTIQC(FASTQC.out.reports.map { sample_id, files -> files }.collect())
}
```

### Step 2: Create enhanced configuration with profiles

Update `nextflow.config`:

```groovy
// Default parameters
params {
    // Input/output
    input = 'data/*.fastq'
    outdir = 'results'
}

// Profile configurations
profiles {
    // Docker profile for local development
    docker {
        docker.enabled = true
        docker.runOptions = '-u $(id -u):$(id -g)'
    }

    // Singularity profile for HPC
    singularity {
        singularity.enabled = true
        singularity.autoMounts = true
    }

    // Apptainer profile (newer name for Singularity)
    apptainer {
        apptainer.enabled = true
        apptainer.autoMounts = true
    }

    // Test profile with minimal resources
    test {
        docker.enabled = true
        docker.runOptions = '-u $(id -u):$(id -g)'

        process {
            cpus = 1
            memory = '2.GB'
        }
    }
}

// Default process configuration
process {
    cpus = 2
    memory = '4.GB'

    // Error handling
    errorStrategy = 'retry'
    maxRetries = 2
}

// Enable reports
report {
    enabled = true
    file = "${params.outdir}/reports/execution_report.html"
}

timeline {
    enabled = true
    file = "${params.outdir}/reports/timeline.html"
}

trace {
    enabled = true
    file = "${params.outdir}/reports/trace.txt"
}
```

### Step 3: Create additional sample data

```bash
# Create a few more samples
cat > data/sample2.fastq << 'EOF'
@SEQ_ID_1
ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG
+
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@SEQ_ID_2
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
+
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
EOF

cat > data/sample3.fastq << 'EOF'
@SEQ_ID_1
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
+
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
@SEQ_ID_2
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
+
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
EOF
```

### Step 4: Run with different profiles

```bash
# Run with Docker (default if you have Docker enabled in config)
nextflow run 02_multiprofile_container.nf -profile docker

# Or explicitly specify the test profile
nextflow run 02_multiprofile_container.nf -profile test

# If you have Singularity/Apptainer (HPC environments)
nextflow run 02_multiprofile_container.nf -profile singularity
# OR
nextflow run 02_multiprofile_container.nf -profile apptainer
```

### What You Should See

1. Multiple processes execute in parallel (one per sample for SEQTK_SAMPLE and FASTQC)
2. Each process runs in its own container
3. MultiQC aggregates all FastQC reports into a single HTML
4. Results appear in `results/qc/` and `results/multiqc/`
5. Execution reports in `results/reports/`

### Key Observations

- **Profile selection** happens at runtime with `-profile`
- **Container images differ per process** — each tool gets its own container
- **The same Docker images work** with both Docker and Singularity runtimes
- **Configuration inheritance** — the test profile extends docker settings

---

## Exercise 3: Challenge — Understanding Seqera Containers and environment.yml

Modern nf-core modules use `environment.yml` files instead of hardcoded container images. Let's explore this pattern.

### Step 1: Create an environment.yml file

Create `environment.yml`:

```yaml
name: fastqc_env
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - bioconda::fastqc=0.11.9
  - conda-forge::python=3.9
```

### Step 2: Understand the Seqera Containers workflow

In production nf-core pipelines:

1. Each module has an `environment.yml` listing conda dependencies
2. Wave (Seqera's service) automatically builds a container from this file
3. The container is cached and shared across the community
4. No manual Docker builds or registry management needed

### Step 3: Configure Wave (optional, requires account)

If you have a Seqera Platform account, you can enable Wave in `nextflow.config`:

```groovy
// Add to your nextflow.config
wave {
    enabled = true
}

tower {
    enabled = true
    accessToken = 'YOUR_TOKEN_HERE'
}
```

Wave will automatically build containers from `environment.yml` files on-the-fly.

### Step 4: Examine an nf-core module structure

Let's look at what a real nf-core module looks like. Create a mock nf-core module structure:

```bash
mkdir -p modules/nf-core/fastqc
```

Create `modules/nf-core/fastqc/main.nf`:

```nextflow
process FASTQC {
    tag "$meta.id"
    label 'process_medium'

    // Modern nf-core pattern: container resolution happens automatically
    // The actual container URL is managed by nf-core infrastructure
    container 'biocontainers/fastqc:0.11.9--0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastqc \\
        $args \\
        --threads $task.cpus \\
        $reads
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_fastqc.html
    touch ${prefix}_fastqc.zip
    """
}
```

Create `modules/nf-core/fastqc/environment.yml`:

```yaml
name: fastqc
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - bioconda::fastqc=0.11.9
```

Create `modules/nf-core/fastqc/meta.yml`:

```yaml
name: fastqc
description: Run FastQC on sequencing reads
keywords:
  - quality control
  - qc
  - sequencing
tools:
  - fastqc:
      description: Quality control tool for high throughput sequence data
      homepage: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
      documentation: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/
      licence: ["GPL-3.0-or-later"]

input:
  - reads:
      type: file
      description: Input sequencing reads (FASTQ format)
      pattern: "*.{fastq,fastq.gz,fq,fq.gz}"

output:
  - html:
      type: file
      description: FastQC HTML report
      pattern: "*_fastqc.html"
  - zip:
      type: file
      description: FastQC report archive
      pattern: "*_fastqc.zip"
```

### What This Shows

In modern nf-core:
- **Developers write `environment.yml`** with conda packages
- **Infrastructure builds containers automatically** via Wave
- **Modules are reusable** across pipelines
- **Version pinning** happens in the environment.yml, not hardcoded containers

---

## Debugging Tips

### 1. Container Not Found / Pull Failed

**Error**: `Unable to pull Docker image 'biocontainers/fastqc:v0.11.9_cv8'`

**Solution**:
- Check your internet connection
- Verify the image name and tag exist on the registry
- Try manually pulling: `docker pull biocontainers/fastqc:v0.11.9_cv8`
- Use Singularity as alternative: `-profile singularity`

### 2. Permission Denied Errors in Docker

**Error**: `Permission denied` when writing output files

**Solution**:
Add `runOptions` to run container as your user:
```groovy
docker {
    runOptions = '-u $(id -u):$(id -g)'
}
```

### 3. Singularity Bind Mount Issues

**Error**: `File not found` when running with Singularity on HPC

**Solution**:
Enable auto-mounting:
```groovy
singularity {
    autoMounts = true
}
```

Or manually specify bind paths:
```groovy
singularity {
    runOptions = '--bind /scratch:/scratch --bind /home:/home'
}
```

### 4. Apptainer vs Singularity Confusion

**Issue**: Not sure which to use?

**Solution**:
- **Apptainer** is the modern open-source continuation of Singularity
- Use `apptainer --version` to check if you have it
- In Nextflow config, use the `apptainer` scope for newer systems
- Older HPC systems may still use `singularity` scope
- Nextflow treats them as separate configuration scopes but they're functionally similar

### 5. Container Pulls Are Slow

**Issue**: Container images are large and take time to download

**Solution**:
- Use Singularity on HPC — images are often pre-cached in shared locations
- Pre-pull commonly used images: `docker pull biocontainers/fastqc:v0.11.9_cv8`
- Consider using Wave with caching enabled for automatic optimization

---

## Key Takeaways

1. **Containers ensure reproducibility** by packaging tools and dependencies together — your pipeline will produce identical results whether it runs on your laptop, an HPC cluster, or in the cloud.

2. **The `container` directive** in Nextflow processes specifies which Docker image to use. Nextflow handles all the complexity of mounting directories, managing permissions, and executing your script inside the container.

3. **Profile-based configuration** lets you switch between Docker (local development) and Singularity/Apptainer (HPC) without changing your workflow code — just run with `-profile docker` or `-profile singularity`.

4. **Modern nf-core uses `environment.yml` + Wave** to automatically build and cache containers, eliminating manual container management and making bioinformatics tools instantly available to the community.

---

## Next Steps

You're now ready for **Session 6 — Configuration: Profiles, params, and resource management**, where you'll dive deeper into the configuration hierarchy, parameter passing, and resource allocation strategies for different compute environments.

---

## Additional Resources

- **Nextflow Containers Documentation**: https://www.nextflow.io/docs/latest/container.html
- **Biocontainers Registry**: https://biocontainers.pro
- **Seqera Containers Documentation**: https://seqera.io/containers/
- **Wave Documentation**: https://seqera.io/wave/
- **nf-core Modules**: https://nf-co.re/modules (see `environment.yml` examples)
