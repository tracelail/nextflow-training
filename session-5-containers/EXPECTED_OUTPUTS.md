# Expected Outputs for Session 5

This document describes what you should see when running each exercise successfully.

---

## Exercise 1: Basic Container Workflow

### Command
```bash
nextflow run 01_basic_container.nf
```

### Expected Console Output
```
N E X T F L O W  ~  version 25.04.6
Launching `01_basic_container.nf` [confident_euler] DSL2 - revision: abc123def

executor >  local (1)
[XX/XXXXXX] process > FASTQC_BASIC (sample1) [100%] 1 of 1 ✔

Pipeline completed!
Check results in: results/fastqc/
Container used: biocontainers/fastqc:v0.11.9_cv8
```

### Expected Directory Structure
```
results/
└── fastqc/
    ├── sample1_fastqc.html
    └── sample1_fastqc.zip

work/
└── [hash]/
    └── [hash]/
        ├── .command.sh
        ├── .command.run
        ├── .command.log
        ├── .command.err
        ├── .exitcode
        └── sample1_fastqc.html
        └── sample1_fastqc.zip
```

### File Verification
```bash
# Check that FastQC HTML report exists
ls -lh results/fastqc/sample1_fastqc.html

# Check file size (should be ~300-500KB)
du -h results/fastqc/sample1_fastqc.html

# View the HTML in browser
open results/fastqc/sample1_fastqc.html  # macOS
# OR
xdg-open results/fastqc/sample1_fastqc.html  # Linux
```

### Key Observations
- FastQC ran without being installed on your system
- Docker image was pulled automatically (may take 1-2 minutes first time)
- Output files were published to results/ directory
- Work directory contains all execution artifacts

---

## Exercise 2: Multi-Profile Workflow

### Command
```bash
# Run with Docker profile
nextflow run 02_multiprofile_container.nf -profile docker -c nextflow_multiprofile.config

# OR run with test profile (faster)
nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config
```

### Expected Console Output
```
N E X T F L O W  ~  version 25.04.6
Launching `02_multiprofile_container.nf` [elegant_darwin] DSL2 - revision: xyz789abc

executor >  local (7)
[XX/XXXXXX] process > SEQTK_SAMPLE (sample3) [100%] 3 of 3 ✔
[XX/XXXXXX] process > FASTQC (sample1)       [100%] 3 of 3 ✔
[XX/XXXXXX] process > MULTIQC                [100%] 1 of 1 ✔

Pipeline completed at: 2026-02-13T10:30:45.123Z
Execution status: SUCCESS
Duration: 1m 23s

Results:
- QC reports: results/qc/
- MultiQC summary: results/multiqc/
- Execution reports: results/reports/

Containers used:
- seqtk: biocontainers/seqtk:v1.3-1-deb_cv1
- FastQC: biocontainers/fastqc:v0.11.9_cv8  
- MultiQC: quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0
```

### Expected Directory Structure
```
results/
├── qc/
│   ├── sample1_sampled_fastqc.html
│   ├── sample1_sampled_fastqc.zip
│   ├── sample2_sampled_fastqc.html
│   ├── sample2_sampled_fastqc.zip
│   ├── sample3_sampled_fastqc.html
│   └── sample3_sampled_fastqc.zip
├── multiqc/
│   ├── multiqc_report.html
│   └── multiqc_data/
│       ├── multiqc_data.json
│       ├── multiqc_fastqc.txt
│       └── multiqc_general_stats.txt
└── reports/
    ├── execution_report.html
    ├── timeline.html
    └── trace.txt
```

### File Verification
```bash
# Check all QC reports exist
ls -lh results/qc/

# Check MultiQC report
ls -lh results/multiqc/multiqc_report.html

# View MultiQC report (aggregates all samples)
open results/multiqc/multiqc_report.html

# Check execution reports
ls -lh results/reports/
```

### Expected MultiQC Report Contents
The MultiQC report should show:
- Summary table with 3 samples
- FastQC quality metrics for each sample
- Per-sequence quality scores plot
- Per-base sequence content
- Sequence length distribution

### Parallel Execution Observation
In the console output, you should see:
- 3 SEQTK_SAMPLE processes running in parallel (one per sample)
- 3 FASTQC processes running in parallel (one per sample)
- 1 MULTIQC process running after all FASTQC processes complete

### Resource Usage
Check the trace file to see resource consumption:
```bash
cat results/reports/trace.txt | column -t
```

Expected columns: task_id, hash, native_id, name, status, exit, submit, duration, realtime, %cpu, %mem, rss, vmem, peak_rss, peak_vmem

---

## Exercise 3: Understanding nf-core Module Structure

### Directory Verification
```bash
# Check module structure
tree modules/nf-core/fastqc/

# Expected output:
# modules/nf-core/fastqc/
# ├── main.nf
# ├── environment.yml
# └── meta.yml
```

### Key Files Content

**main.nf**: Contains the process definition with:
- `tag "$meta.id"` for logging
- `container` directive
- Input/output declarations with `meta` pattern
- Main `script` block
- `stub` block for testing

**environment.yml**: Lists conda dependencies:
```yaml
name: fastqc
channels:
  - conda-forge
  - bioconda
dependencies:
  - bioconda::fastqc=0.11.9
```

**meta.yml**: Provides metadata about the module:
- Tool description
- Input/output specifications
- Keywords and documentation links

### What This Demonstrates

1. **Separation of Concerns**:
   - Process logic in `main.nf`
   - Dependencies in `environment.yml`
   - Documentation in `meta.yml`

2. **Portability**:
   - Same module works in any nf-core pipeline
   - Container built automatically from environment.yml
   - No manual Docker registry management

3. **Community Standards**:
   - Follows nf-core conventions
   - Ready for contribution to nf-core/modules
   - Lintable with `nf-core modules lint`

---

## Common Issues and Solutions

### Issue 1: Docker Image Pull Fails
**Error**: `Unable to pull Docker image`

**Solution**:
```bash
# Manually pull the image
docker pull biocontainers/fastqc:v0.11.9_cv8

# Check Docker is running
docker ps

# Try with test profile (smaller images)
nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config
```

### Issue 2: Permission Denied Errors
**Error**: `Permission denied` when creating output files

**Expected**: This should NOT happen if you're using the provided config

**Verification**: Check that your config includes:
```groovy
docker {
    runOptions = '-u $(id -u):$(id -g)'
}
```

### Issue 3: No Output Files Created
**Check**:
```bash
# Look at work directory
ls work/*/*/

# Check error logs
cat work/*/*/.command.err

# Check exit code
cat work/*/*/.exitcode  # Should be 0 for success
```

### Issue 4: Container Command Not Found
**Error**: `.command.sh: line X: fastqc: command not found`

**Possible Causes**:
- Wrong container image specified
- Container pulled but tool not in PATH
- Architecture mismatch (M1 Mac running amd64 image)

**Solution**:
```bash
# Verify container has the tool
docker run biocontainers/fastqc:v0.11.9_cv8 fastqc --version

# Check container platform
docker image inspect biocontainers/fastqc:v0.11.9_cv8 | grep Architecture
```

---

## Validation Checklist

After completing all exercises, verify:

- [ ] Exercise 1 produces FastQC HTML and ZIP files
- [ ] Exercise 2 produces QC reports for all 3 samples
- [ ] Exercise 2 produces MultiQC aggregated report
- [ ] Execution reports exist in results/reports/
- [ ] Work directories contain .command.sh, .command.log
- [ ] No permission errors in .command.err
- [ ] Exit codes are 0 in .exitcode files
- [ ] Can open and view FastQC and MultiQC HTML reports
- [ ] Timeline report shows parallel execution
- [ ] Module structure matches nf-core conventions

---

## Performance Expectations

### Exercise 1 (Single Sample)
- **First run**: 2-3 minutes (includes image pull)
- **Subsequent runs**: 10-20 seconds (with -resume)
- **Docker image size**: ~350 MB

### Exercise 2 (Three Samples + MultiQC)
- **First run**: 3-5 minutes (includes multiple image pulls)
- **Subsequent runs**: 30-45 seconds (with -resume)
- **Total Docker images**: ~800 MB
- **Parallel processes**: Up to 3 (limited by sample count)

### Disk Usage
```bash
# Check results size
du -sh results/

# Expected: ~2-5 MB (HTML reports are small with toy data)

# Check work directory size
du -sh work/

# Expected: ~10-15 MB (includes all intermediate files)

# Check Docker images
docker images | grep -E 'fastqc|seqtk|multiqc'

# Expected: 3 images totaling ~800 MB
```

---

## Next Steps

After successfully completing Session 5, you should:

1. **Understand container basics**: How containers ensure reproducibility
2. **Know configuration patterns**: Profile-based runtime selection
3. **Recognize nf-core standards**: Module structure with environment.yml
4. **Be ready for Session 6**: Advanced configuration and resource management

**Session 6 Preview**: You'll learn about:
- Configuration hierarchy and precedence
- Dynamic resource allocation
- Executor configuration for HPC
- Advanced profile strategies
