# Expected Outputs — Session 6

This document describes what outputs you should see after completing each exercise successfully.

## Exercise 1: Basic Configuration and Parameter Override

### After Step 2 (default parameters)
```
results/
└── greeting.txt
```

**Contents of greeting.txt:**
```
Hello, World!
Hello, World!
Hello, World!
```

### After Step 3 (CLI override)
```
results/
└── greeting.txt
```

**Contents of greeting.txt:**
```
Bonjour, Claude!
Bonjour, Claude!
Bonjour, Claude!
Bonjour, Claude!
Bonjour, Claude!
```

### After Step 4 (params file)
```
spanish_results/
└── greeting.txt
```

**Contents of greeting.txt:**
```
Hola, Nextflow!
Hola, Nextflow!
```

### After Step 5 (precedence test)
```
spanish_results/
└── greeting.txt
```

**Contents of greeting.txt:**
```
Hola, Jimmy!
Hola, Jimmy!
```

**Key observation:** The greeting came from `params.yaml` (lower precedence) but the name came from the CLI `--name Jimmy` (higher precedence), demonstrating the configuration hierarchy.

---

## Exercise 2: Multi-Profile Configuration

### Local Profile Execution

**Expected console output:**
```
N E X T F L O W  ~  version 25.04.6
Launching `analysis_pipeline.nf` [pedantic_euler] DSL2 - revision: 1a2b3c4d5e

executor >  local (4)
[xx/yyyyyy] process > ANALYZE (3)   [100%] 3 of 3 ✔
[aa/bbbbbb] process > SUMMARIZE (1) [100%] 1 of 1 ✔
```

**Output directory structure:**
```
results/
├── sample1_report.txt
├── sample2_report.txt
├── sample3_report.txt
└── summary.txt
```

**Contents of sample1_report.txt (local profile):**
```
Analyzing sample1
Memory: 2 GB
CPUs: 1
Container: 
Analysis complete
```

**Note:** Container field is empty because local profile doesn't enable containers.

### Docker Profile Execution

**Contents of sample1_report.txt (docker profile):**
```
Analyzing sample1
Memory: 2 GB
CPUs: 1
Container: ubuntu:22.04
Analysis complete
```

**Key observation:** The container field now shows the container image being used.

### Laptop Profile Execution

**Contents of sample1_report.txt (laptop profile with resource limits):**
```
Analyzing sample1
Memory: 1 GB
CPUs: 1
Container: ubuntu:22.04
Analysis complete
```

**Contents of summary.txt (laptop profile):**
```
Summary Report
=============
Analyzing sample2
Memory: 2 GB
CPUs: 2
Container: ubuntu:22.04
Analysis complete
```

**Key observation:** The `SUMMARIZE` process (labeled `process_medium`) gets more resources (2 GB, 2 CPUs) than `ANALYZE` (labeled `process_low`).

---

## Exercise 3: SLURM Configuration and Advanced Selectors

### Preview Mode Output

When running with `-preview`, you should see:

```
executor >  slurm
[--/------] process > ANALYZE
[--/------] process > SUMMARIZE

NOTE: Process execution has been disabled by preview mode
```

**Key observation:** No jobs are actually submitted to SLURM, but Nextflow shows you what would be executed.

### Using nextflow config Command

Run this command:
```bash
nextflow config -profile slurm
```

**Expected output (partial):**
```
process {
   executor = 'slurm'
   queue = 'general'
   clusterOptions = '--account=myproject'
   cpus = 1
   memory = '2 GB'
   time = '1 h'
   withLabel:process_low {
      cpus = 2
      memory = '4 GB'
      time = '2 h'
   }
   withName:SUMMARIZE {
      cpus = 1
      memory = '2 GB'
      time = '30 m'
      queue = 'express'
   }
}
```

**Key observation:** The `withName: SUMMARIZE` override takes precedence, giving it different settings than the `process_medium` label would provide.

### Resource Test Output

When running `resource_test.nf` with `-profile laptop`:

**Console output:**
```
Tiny: Tiny: 1 CPUs, 1 GB
Medium: Medium: 2 CPUs, 2 GB
Huge: Huge: 3 CPUs, 4 GB
Custom: Custom: 1 CPUs, 2 GB
```

**Key observations:**
1. `HUGE_TASK` requested `process_high` (which would normally be 4 CPUs, 8 GB) but was capped by `resourceLimits` to 3 CPUs, 4 GB
2. `CUSTOM_TASK` has no label, so it gets the default settings (1 CPU, 2 GB from base process config)
3. Labels provide consistent resource allocation patterns across the pipeline

---

## Verification Commands

Use these commands to verify your setup:

### Check resolved configuration
```bash
nextflow config -profile docker
```

### Check specific profile
```bash
nextflow config -profile laptop -show-profiles
```

### Inspect process settings
```bash
nextflow config -profile slurm | grep -A 20 "withLabel:process_medium"
```

### View execution report
```bash
nextflow run analysis_pipeline.nf -profile docker -with-report report.html
```
Then open `report.html` in a browser to see resource usage, execution times, and more.

---

## Common Issues and Their Outputs

### Issue: Forgot to specify profile

**Command:**
```bash
nextflow run analysis_pipeline.nf
```

**Result:** Pipeline runs with default settings (no containers, minimal resources). Check the output files — the Container field will be empty.

### Issue: Profile name typo

**Command:**
```bash
nextflow run analysis_pipeline.nf -profile dockerr
```

**Error output:**
```
ERROR ~ Unknown profile: 'dockerr'
```

### Issue: Using single dash for parameter

**Command:**
```bash
nextflow run simple_config.nf -name "Test"
```

**Result:** Parameter is ignored (treated as Nextflow option, not pipeline param). The output will still say "World" instead of "Test".

**Correct command:**
```bash
nextflow run simple_config.nf --name "Test"
```

---

## Work Directory Inspection

After any run, explore the work directory to understand execution:

```bash
cd work
ls -la */
```

Each subdirectory contains:
- `.command.sh` — The actual script that was executed
- `.command.log` — Standard output from the script
- `.command.err` — Error output (if any)
- `.command.run` — Nextflow wrapper script
- `.exitcode` — Process exit code (0 = success)
- Output files created by the process

**Example inspection:**
```bash
# Find the work directory for ANALYZE process
nextflow log -f 'process,hash,name' | grep ANALYZE

# Navigate to that directory
cd work/xx/yyyyyyyy...

# Read the command that was executed
cat .command.sh

# Check resource allocation
cat .command.run | grep -E "cpus|memory"
```

---

## Success Criteria

You have successfully completed Session 6 if:

1. ✅ You can override parameters using CLI (`--param`), params file (`-params-file`), and config files (`-c`)
2. ✅ You can switch execution environments with profiles (`-profile docker`, `-profile local`)
3. ✅ You understand how `withLabel` and `withName` selectors work
4. ✅ You can inspect resolved configuration with `nextflow config`
5. ✅ You can explain the 6-level configuration precedence hierarchy
6. ✅ Your pipeline produces identical results regardless of profile (demonstrating portability)
7. ✅ You can use `resourceLimits` to cap resources for development environments

---

## Next Session Preview

**Session 7** covers Groovy essentials for Nextflow developers. You'll learn about:
- Data structures (Lists, Maps) with proper syntax
- Closures with explicit parameters (no more implicit `it`)
- Functional collection methods
- String interpolation and manipulation
- Parsing filenames into structured metadata

This builds on the configuration knowledge you've gained here by teaching you how to manipulate parameters and build sophisticated data transformations in your workflows.
