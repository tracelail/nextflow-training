# Session 5 Quick Start Guide

## Prerequisites Check

Before starting, verify your environment:

```bash
# Check Nextflow installation
nextflow -version  # Should be 25.04.0 or later

# Check Docker (if using Docker)
docker --version
docker ps

# OR check Singularity/Apptainer (if using HPC)
singularity --version
# OR
apptainer --version
```

## Quick Start Commands

### Exercise 1: Basic Container Usage

```bash
# Run the basic container workflow
nextflow run 01_basic_container.nf

# View results
open results/fastqc/sample1_fastqc.html  # macOS
xdg-open results/fastqc/sample1_fastqc.html  # Linux

# Clean up for next run
nextflow clean -f
rm -rf results/ work/ .nextflow*
```

### Exercise 2: Multi-Profile Workflow

```bash
# Run with Docker profile
nextflow run 02_multiprofile_container.nf -profile docker -c nextflow_multiprofile.config

# OR run with test profile (faster, fewer reads)
nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config

# View MultiQC report
open results/multiqc/multiqc_report.html

# View execution timeline
open results/reports/timeline.html

# Clean up
nextflow clean -f
rm -rf results/ work/ .nextflow*
```

### Exercise 3: Explore nf-core Module Structure

```bash
# View the module structure
tree modules/nf-core/fastqc/

# Read each file
cat modules/nf-core/fastqc/main.nf
cat modules/nf-core/fastqc/environment.yml
cat modules/nf-core/fastqc/meta.yml
```

## Common Commands

### Working with Docker

```bash
# List downloaded images
docker images

# Pull an image manually
docker pull biocontainers/fastqc:v0.11.9_cv8

# Test an image interactively
docker run -it biocontainers/fastqc:v0.11.9_cv8 /bin/bash

# Check tool version in container
docker run biocontainers/fastqc:v0.11.9_cv8 fastqc --version

# Remove all unused images (cleanup)
docker image prune -a
```

### Working with Nextflow

```bash
# Run with resume (skip completed tasks)
nextflow run 02_multiprofile_container.nf -profile docker -resume -c nextflow_multiprofile.config

# View execution log
nextflow log

# Get details about last run
nextflow log -f 'name,status,exit,duration'

# Clean work directory
nextflow clean -f

# Preview run without executing (dry-run)
nextflow run 02_multiprofile_container.nf -profile docker -preview -c nextflow_multiprofile.config
```

### Inspecting Results

```bash
# List all outputs
find results/ -type f

# Check file sizes
du -h results/qc/*
du -h results/multiqc/*

# View trace file
cat results/reports/trace.txt | column -t

# Count work directories (= number of tasks)
find work/ -name '.command.sh' | wc -l
```

## Troubleshooting Quick Fixes

### Docker Not Running
```bash
# Start Docker Desktop (macOS/Windows)
# OR
sudo systemctl start docker  # Linux
```

### Permission Issues
```bash
# Make sure config has runOptions
grep -A2 'docker {' nextflow.config

# Should see: runOptions = '-u $(id -u):$(id -g)'
```

### Image Pull Fails
```bash
# Try pulling manually
docker pull biocontainers/fastqc:v0.11.9_cv8

# Check internet connection
ping google.com

# Try with Singularity instead
nextflow run 02_multiprofile_container.nf -profile singularity -c nextflow_multiprofile.config
```

### Process Fails
```bash
# Find the failing work directory
nextflow log -f 'status,exit,workdir'

# Look at the error
cat work/[hash]/[hash]/.command.err

# Look at what was executed
cat work/[hash]/[hash]/.command.sh

# Check exit code
cat work/[hash]/[hash]/.exitcode
```

## File Organization Reference

```
session-5-containers/
├── README.md                      # Main documentation
├── EXPECTED_OUTPUTS.md            # What to expect when running
├── QUICKSTART.md                  # This file
├── 01_basic_container.nf          # Exercise 1 workflow
├── 02_multiprofile_container.nf   # Exercise 2 workflow
├── nextflow.config                # Basic config for Exercise 1
├── nextflow_multiprofile.config   # Advanced config for Exercise 2
├── environment.yml                # Example conda environment
├── data/                          # Sample FASTQ files
│   ├── sample1.fastq
│   ├── sample2.fastq
│   └── sample3.fastq
└── modules/                       # nf-core module example
    └── nf-core/
        └── fastqc/
            ├── main.nf
            ├── environment.yml
            └── meta.yml
```

## Exercise Progression

1. **Start with Exercise 1** - Learn basic container usage
2. **Move to Exercise 2** - Understand multi-profile configuration
3. **Explore Exercise 3** - See nf-core module structure

## Time Estimates

- **Exercise 1**: 15-20 minutes (including reading)
- **Exercise 2**: 25-30 minutes (including reading)
- **Exercise 3**: 10-15 minutes (reading and exploration)
- **Total Session**: 50-65 minutes

## Success Criteria

You've successfully completed Session 5 when you can:
- ✅ Run a containerized process
- ✅ Switch between Docker and Singularity profiles
- ✅ Understand container directive usage
- ✅ Recognize nf-core module structure
- ✅ Explain why containers ensure reproducibility

## Getting Help

If you encounter issues:

1. Check EXPECTED_OUTPUTS.md for common problems
2. Review README.md for concept explanations
3. Inspect work directories for error messages
4. Check nextflow.log for detailed logs
5. Verify Docker/Singularity is running

## Next Session Preview

**Session 6** will cover:
- Configuration hierarchy and precedence
- Dynamic resource allocation with selectors
- Executor configuration for HPC clusters
- Advanced profile strategies
- Parameter passing and validation
