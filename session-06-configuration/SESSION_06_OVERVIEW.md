# Session 6 Materials — Overview

## Package Contents

This archive contains complete materials for **Session 6: Configuration — Profiles, params, and resource management** from your Nextflow Training Curriculum.

### 📦 What's Included

**Core Documentation:**
- `README.md` — Complete session guide with learning objectives, concepts, and exercises
- `QUICK_START.md` — Condensed reference for rapid execution
- `EXPECTED_OUTPUTS.md` — Detailed descriptions of expected results for verification
- `CONFIG_REFERENCE.md` — Quick reference card for configuration directives and patterns

**Pipeline Files:**
- `simple_config.nf` — Basic parameter demonstration (Exercise 1)
- `analysis_pipeline.nf` — Multi-process pipeline with labels (Exercise 2)
- `resource_test.nf` — Resource allocation testing (Exercise 3)

**Configuration Files:**
- `nextflow.config` — Multi-profile configuration (local, docker, singularity, laptop, slurm)
- `hpc_overrides.config` — Example configuration overrides
- `params.yaml` — Example YAML parameters file
- `params.json` — Example JSON parameters file

### 🎯 Learning Objectives

After completing this session, you will master:

1. **Configuration Hierarchy** — Understand and apply the 6-level precedence system
2. **Multi-Profile Setup** — Create configurations for different execution environments
3. **Parameter Management** — Define, override, and organize pipeline parameters
4. **Process Selectors** — Use `withName` and `withLabel` for targeted configuration
5. **Resource Management** — Apply `resourceLimits` and resource directives effectively
6. **Executor Configuration** — Configure SLURM, local, and container executors

### ⚡ Quick Start

```bash
# Extract the archive
tar -xzf session-06-configuration.tar.gz
cd session-06-configuration

# Start with the README
cat README.md | less

# Or jump straight to exercises
cat QUICK_START.md
```

### 📋 Exercises Overview

**Exercise 1: Basic Configuration (5 min)**
- Default parameters
- CLI overrides with `--param`
- Params files (YAML/JSON)
- Configuration precedence

**Exercise 2: Multi-Profile Configuration (10 min)**
- Local, Docker, Singularity profiles
- Resource allocation with labels
- Resource limits with `resourceLimits`
- Configuration inspection

**Exercise 3: SLURM and Advanced Selectors (15 min)**
- SLURM executor configuration
- Process-specific overrides with `withName`
- Configuration file composition
- Preview mode testing

**Total Time:** ~30 minutes + exploration

### 🔧 Prerequisites

From your training progression, you should have:
- ✅ Completed Sessions 1-5
- ✅ Docker or Singularity/Apptainer installed
- ✅ Nextflow 25.04.6 installed
- ✅ Understanding of processes, workflows, and containers

### 📚 Key Concepts Covered

- **Configuration scopes:** params, process, docker, singularity, executor
- **Profile patterns:** standard, docker, singularity, laptop, slurm, test
- **Process directives:** cpus, memory, time, queue, container, label
- **Selector patterns:** withName, withLabel, pattern matching
- **Resource limits:** Global caps with resourceLimits directive
- **Precedence hierarchy:** CLI → params-file → -c → nextflow.config → defaults

### 🎓 2026 Compliance Notes

All materials follow 2026 best practices:
- ✅ Lowercase `channel` factories (not `Channel.`)
- ✅ Explicit closure parameters (no implicit `it`)
- ✅ Modern DSL2 syntax
- ✅ Current Nextflow 25.04+ features
- ✅ nf-core compatible patterns

### 🚀 After This Session

You'll be ready for **Session 7: Groovy Essentials**, which builds on this configuration knowledge by teaching:
- Data structure manipulation (Lists, Maps)
- Functional programming patterns
- String interpolation and parsing
- Closure composition techniques

### 📖 Documentation References

Core concepts align with:
- training.nextflow.io "Hello Nextflow Part 6"
- training.nextflow.io "Advanced: Configuration"
- Current Nextflow docs (25.04.6+)

### ✅ Success Criteria

Complete the session successfully by:
1. Running pipelines with multiple profiles
2. Overriding parameters via CLI and files
3. Applying resource directives with selectors
4. Inspecting resolved configuration
5. Understanding precedence hierarchy
6. Testing resource limits
7. Configuring executor settings

### 💡 Tips for Success

1. **Read README.md first** — It contains detailed explanations
2. **Use QUICK_START.md** — For rapid execution commands
3. **Check EXPECTED_OUTPUTS.md** — Verify your results match
4. **Keep CONFIG_REFERENCE.md handy** — Quick syntax lookup
5. **Experiment** — Try modifying configs to see effects
6. **Use `nextflow config`** — Inspect resolved configuration
7. **Explore work directories** — Understand execution details

### 🐛 Troubleshooting

Common issues and solutions are documented in:
- README.md "Debugging Tips" section
- EXPECTED_OUTPUTS.md "Common Issues" section

Quick fixes:
- Params need `--` (double-dash)
- Profiles need `-` (single-dash)
- Check Docker/Singularity is running
- Verify you're in correct directory
- Use `nextflow config` to debug

### 📦 Archive Size

**12 KB compressed** — Contains all materials for offline use

### 🔗 Session Context

This is Session 6 of your 20-session curriculum:
- **Phase 1** (Sessions 1-12): Core Nextflow concepts
- **Current:** Session 6 — Configuration mastery
- **Next:** Session 7 — Groovy essentials
- **Upcoming:** Sessions 8-12 (operators, testing, debugging)

### 🎯 Connection to nf-core

Configuration patterns taught here are:
- Essential for nf-core pipelines
- Used in all community modules
- Required for pipeline portability
- Foundation for HPC execution
- Critical for reproducibility

The resource class labels (`process_low`, `process_medium`, `process_high`) are the **nf-core standard** and will appear in every community pipeline you encounter.

---

## Ready to Begin?

```bash
tar -xzf session-06-configuration.tar.gz
cd session-06-configuration
less README.md
```

Happy learning! 🚀
