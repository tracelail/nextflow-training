# Session 5: Solutions and Extensions

This document provides solutions to common modifications and extensions for Session 5 exercises.

---

## Extension 1: Adding a New Tool Container

**Challenge**: Add a process that uses `samtools` to convert a SAM file to BAM.

### Solution

Add this process to `02_multiprofile_container.nf`:

```nextflow
process SAMTOOLS_VIEW {
    tag "$sample_id"
    container 'biocontainers/samtools:v1.15.1-deb_cv1'
    
    publishDir 'results/bam', mode: 'copy'
    
    input:
    tuple val(sample_id), path(sam_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam
    
    script:
    """
    samtools view -bS ${sam_file} > ${sample_id}.bam
    """
}
```

**Key Learning**: Each tool gets its own container. Nextflow handles pulling and managing multiple images.

---

## Extension 2: Using Singularity on HPC

**Challenge**: Configure the workflow to run on an HPC cluster with SLURM.

### Solution

Create `nextflow_hpc.config`:

```groovy
// HPC Configuration
profiles {
    slurm {
        process {
            executor = 'slurm'
            queue = 'general'
            
            cpus = 4
            memory = '8.GB'
            time = '2.h'
            
            // Process-specific resource allocation
            withName: FASTQC {
                cpus = 2
                memory = '4.GB'
            }
            
            withName: MULTIQC {
                cpus = 1
                memory = '2.GB'
            }
        }
        
        // Use Singularity for containers
        singularity {
            enabled = true
            autoMounts = true
            cacheDir = '/scratch/singularity_cache'
        }
    }
}
```

Run with:
```bash
nextflow run 02_multiprofile_container.nf -profile slurm -c nextflow_hpc.config
```

**Key Learning**: Profiles can combine executor settings with container runtime configuration.

---

## Extension 3: Custom Container Build

**Challenge**: Create your own Docker container for a custom tool.

### Solution

Create a `Dockerfile`:

```dockerfile
FROM ubuntu:20.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install your custom tool
RUN pip3 install biopython pandas

# Add your script
COPY my_analysis.py /usr/local/bin/
RUN chmod +x /usr/local/bin/my_analysis.py

# Set working directory
WORKDIR /data

CMD ["/bin/bash"]
```

Build and push:
```bash
# Build locally
docker build -t myusername/myanalysis:1.0 .

# Test it
docker run -it myusername/myanalysis:1.0 python3 --version

# Push to Docker Hub (requires login)
docker login
docker push myusername/myanalysis:1.0
```

Use in Nextflow:
```nextflow
process MY_ANALYSIS {
    container 'myusername/myanalysis:1.0'
    
    input:
    path(input_file)
    
    output:
    path('results.txt')
    
    script:
    """
    my_analysis.py ${input_file} > results.txt
    """
}
```

**Key Learning**: You can build custom containers for tools not in Biocontainers.

---

## Extension 4: Container with GPU Support

**Challenge**: Run a GPU-accelerated tool in a container.

### Solution

Configure Docker with GPU support in `nextflow.config`:

```groovy
process {
    withLabel: 'gpu' {
        container = 'nvcr.io/nvidia/pytorch:23.10-py3'
        containerOptions = '--gpus all'
        accelerator = 1
    }
}

docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g) --gpus all'
}
```

Use in a process:
```nextflow
process PYTORCH_INFERENCE {
    label 'gpu'
    
    input:
    path(model)
    path(data)
    
    output:
    path('predictions.csv')
    
    script:
    """
    python3 run_inference.py --model ${model} --data ${data} --gpu
    """
}
```

**Requirements**: 
- NVIDIA GPU
- NVIDIA Container Toolkit installed
- Docker configured for GPU access

---

## Extension 5: Multi-Platform Container Support

**Challenge**: Support both AMD64 and ARM64 architectures (e.g., M1 Macs).

### Solution

Add platform configuration:

```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
    
    // Pull multi-platform images
    registry = 'quay.io'
}

profiles {
    arm64 {
        docker.runOptions = '-u $(id -u):$(id -g) --platform linux/arm64'
    }
    
    amd64 {
        docker.runOptions = '-u $(id -u):$(id -g) --platform linux/amd64'
    }
    
    // M1 Mac with emulation
    m1_emulated {
        docker.runOptions = '-u $(id -u):$(id -g) --platform linux/amd64'
        
        process {
            // Reduce resources for emulation overhead
            cpus = { task.cpus / 2 }
            memory = { task.memory * 0.8 }
        }
    }
}
```

**Key Learning**: Platform-specific configurations handle architecture differences.

---

## Extension 6: Container Registry Authentication

**Challenge**: Use containers from a private registry.

### Solution

Configure credentials in `nextflow.config`:

```groovy
docker {
    enabled = true
    registry = 'myregistry.company.com'
    
    // Option 1: Use existing Docker credentials
    // (requires prior `docker login myregistry.company.com`)
    
    // Option 2: Specify credentials file
    // docker.config = '/path/to/docker/config.json'
}

// For Singularity with private registry
singularity {
    enabled = true
    
    // Singularity automatically uses Docker credentials
    // Just ensure you've run: singularity remote login
}
```

For GitHub Container Registry:
```bash
# Login to ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Use in container directive
container 'ghcr.io/myorg/myimage:latest'
```

---

## Extension 7: Optimizing Container Layer Caching

**Challenge**: Speed up container builds with better layer caching.

### Solution

Structure your Dockerfile for optimal caching:

```dockerfile
FROM ubuntu:20.04

# 1. Install system dependencies (changes rarely)
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. Install base Python packages (changes occasionally)
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

# 3. Copy your code (changes frequently)
COPY scripts/ /usr/local/bin/

# 4. Set up environment
WORKDIR /data
ENV PATH="/usr/local/bin:${PATH}"
```

**Key Principle**: Order commands from least to most frequently changing.

---

## Extension 8: Container Health Checks

**Challenge**: Ensure containers are working before running processes.

### Solution

Add health checks to your Dockerfile:

```dockerfile
FROM biocontainers/fastqc:v0.11.9_cv8

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD fastqc --version || exit 1
```

In Nextflow, verify tools:
```nextflow
process CHECK_TOOL {
    container 'biocontainers/fastqc:v0.11.9_cv8'
    
    output:
    stdout
    
    script:
    """
    fastqc --version
    """
}

workflow {
    // Check tool is available before proceeding
    CHECK_TOOL()
    CHECK_TOOL.out.view()
    
    // Continue with main workflow
    // ...
}
```

---

## Extension 9: Wave for On-Demand Container Building

**Challenge**: Build containers automatically from conda environments.

### Solution

Enable Wave in `nextflow.config`:

```groovy
wave {
    enabled = true
}

tower {
    enabled = true
    accessToken = 'YOUR_SEQERA_TOKEN'
}

conda {
    enabled = true
}
```

Create a process with conda directive:

```nextflow
process FASTQC_WAVE {
    conda 'bioconda::fastqc=0.11.9'
    
    input:
    tuple val(meta), path(reads)
    
    output:
    path("*.html")
    
    script:
    """
    fastqc ${reads}
    """
}
```

**What Happens**:
1. Wave reads the conda directive
2. Builds a container with those packages
3. Caches it for reuse
4. No manual Docker build needed!

---

## Extension 10: Testing Container Changes Locally

**Challenge**: Test modified containers before pushing to registry.

### Solution

Build and test locally:

```bash
# Build with a local tag
docker build -t fastqc:local-test .

# Test interactively
docker run -it -v $(pwd):/data fastqc:local-test /bin/bash

# In the container, test your tool
fastqc --version
fastqc /data/sample1.fastq

# Exit container
exit

# Use in Nextflow
nextflow run test.nf --container_tag 'local-test'
```

In your workflow:
```nextflow
params.container_tag = 'v0.11.9_cv8'

process FASTQC {
    container "biocontainers/fastqc:${params.container_tag}"
    
    // ...
}
```

**Key Learning**: Use parameters to switch between container versions for testing.

---

## Debugging Container Issues

### Issue: Container fails with "exec format error"

**Cause**: Architecture mismatch (e.g., ARM64 container on AMD64 host)

**Solution**:
```bash
# Check image architecture
docker image inspect biocontainers/fastqc:v0.11.9_cv8 | grep Architecture

# Pull specific platform
docker pull --platform linux/amd64 biocontainers/fastqc:v0.11.9_cv8

# Use platform flag in Nextflow
docker.runOptions = '--platform linux/amd64'
```

### Issue: Container can't access files

**Cause**: Mount point not configured

**Solution**:
```groovy
// For Singularity
singularity {
    autoMounts = true
    
    // Or manually specify
    runOptions = '--bind /scratch:/scratch --bind /data:/data'
}

// For Docker
docker {
    runOptions = '-v /scratch:/scratch -v /data:/data'
}
```

### Issue: Container pulls are timing out

**Solution**:
```bash
# Increase timeout
export NXF_ANSI_LOG=false
export NXF_DOCKER_TIMEOUT=600000  # 10 minutes in ms

# Or configure in nextflow.config
docker {
    timeout = '10 min'
}
```

---

## Best Practices Summary

1. **Version pinning**: Always specify exact container tags
   ```nextflow
   container 'biocontainers/fastqc:v0.11.9_cv8'  // ✅ Good
   container 'biocontainers/fastqc:latest'       // ❌ Bad
   ```

2. **Minimal images**: Use slim/alpine base images when possible
3. **Layer optimization**: Order Dockerfile commands by change frequency
4. **Security**: Don't run as root; use `runOptions = '-u $(id -u):$(id -g)'`
5. **Caching**: Pre-pull images on HPC shared filesystems
6. **Testing**: Test containers interactively before using in workflows
7. **Documentation**: Document which containers are used in your README

---

## Additional Challenges

Try these on your own:

1. **Multi-stage builds**: Create a Dockerfile with build and runtime stages
2. **Container composition**: Chain multiple containers in a workflow
3. **Dynamic container selection**: Choose containers based on input data type
4. **Container versioning**: Implement a strategy for managing container versions
5. **Resource limits**: Set memory/CPU limits within containers
6. **Logging**: Capture and parse container logs for debugging

---

## Resources for Further Learning

- **Docker Documentation**: https://docs.docker.com/
- **Singularity Documentation**: https://sylabs.io/docs/
- **Biocontainers**: https://biocontainers.pro/
- **Wave Documentation**: https://seqera.io/wave/
- **nf-core Container Guidelines**: https://nf-co.re/docs/contributing/modules#docker-containers
