# Session 5 Materials - File Guide

This document serves as a complete manifest of all Session 5 materials and explains what each file contains.

## Quick Navigation

- **Start Here**: [README.md](#readme)
- **Quick Start**: [QUICKSTART.md](#quickstart)
- **Exercises**: [Workflow Files](#workflow-files)
- **Help**: [EXPECTED_OUTPUTS.md](#expected-outputs)
- **Extensions**: [SOLUTIONS_AND_EXTENSIONS.md](#solutions)

---

## Documentation Files

### README.md
**Purpose**: Main learning document for Session 5
**Size**: ~25 KB
**Contents**:
- Learning objectives and prerequisites
- Detailed concept explanations (containers, runtimes, Seqera Containers)
- Three progressive exercises with step-by-step instructions
- Debugging tips and common issues
- Key takeaways and next steps

**When to use**: Read this first to understand container concepts, then follow the exercises

---

### QUICKSTART.md
**Purpose**: Fast-track commands for experienced users
**Size**: ~8 KB
**Contents**:
- Prerequisites checklist
- Copy-paste commands for all exercises
- Common command reference
- Troubleshooting quick fixes
- File organization overview

**When to use**: If you want to quickly run the exercises without detailed explanations

---

### EXPECTED_OUTPUTS.md
**Purpose**: Validation guide showing expected results
**Size**: ~15 KB
**Contents**:
- Console output examples
- Directory structure diagrams
- File verification commands
- Performance expectations
- Common issues and solutions
- Validation checklist

**When to use**: After running exercises to verify everything worked correctly

---

### SOLUTIONS_AND_EXTENSIONS.md
**Purpose**: Advanced patterns and additional challenges
**Size**: ~18 KB
**Contents**:
- 10 extension exercises (GPU, multi-platform, Wave, etc.)
- Solutions to common modifications
- Best practices summary
- Debugging advanced issues
- Additional challenge ideas

**When to use**: After completing main exercises, to go deeper

---

### SESSION_SUMMARY.md
**Purpose**: Recap of learning outcomes
**Size**: ~10 KB
**Contents**:
- Concepts mastered
- Skills developed
- Key syntax patterns
- Connection to other sessions
- Self-assessment questions
- Practice ideas

**When to use**: After completing exercises, for review and consolidation

---

## Workflow Files

### 01_basic_container.nf
**Purpose**: Exercise 1 - Introduction to containers
**Size**: ~1 KB
**Complexity**: ⭐ Basic
**Runtime**: ~30 seconds (after image pull)
**Features**:
- Single process with container directive
- FastQC quality control
- publishDir output management
- Basic workflow structure

**Demonstrates**:
- Container directive syntax
- Automatic container pulling
- Work directory mounting
- Output publishing

**Run with**:
```bash
nextflow run 01_basic_container.nf
```

---

### 02_multiprofile_container.nf
**Purpose**: Exercise 2 - Multi-tool, multi-profile pipeline
**Size**: ~3 KB
**Complexity**: ⭐⭐⭐ Intermediate
**Runtime**: ~1-2 minutes (after image pulls)
**Features**:
- Three processes (SEQTK_SAMPLE, FASTQC, MULTIQC)
- Different containers per tool
- Channel operations (map, collect)
- Named outputs with emit
- Workflow completion handler

**Demonstrates**:
- Multiple containerized processes
- Profile-based configuration
- Parallel execution
- Data aggregation
- Report generation

**Run with**:
```bash
nextflow run 02_multiprofile_container.nf -profile docker -c nextflow_multiprofile.config
# OR
nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config
```

---

## Configuration Files

### nextflow.config
**Purpose**: Basic configuration for Exercise 1
**Size**: ~500 bytes
**Scope**: Global defaults
**Contents**:
- Docker enabled
- runOptions for permissions
- Basic resource settings

**Key Settings**:
```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
}
```

---

### nextflow_multiprofile.config
**Purpose**: Advanced multi-profile configuration for Exercise 2
**Size**: ~2 KB
**Scope**: Profile-based settings
**Contents**:
- Four profiles (docker, singularity, apptainer, test)
- Parameter definitions
- Execution reports enabled
- Manifest metadata

**Key Features**:
- Profile selection: `-profile docker` or `-profile test`
- Resource allocation per profile
- Automatic report generation
- Container runtime switching

**Profiles**:
- `docker`: For local development
- `singularity`: For HPC with Singularity
- `apptainer`: For HPC with Apptainer
- `test`: Minimal resources for quick testing

---

## Data Files

### data/sample1.fastq
**Purpose**: Primary test sample
**Size**: ~500 bytes
**Format**: FASTQ (text-based sequencing data)
**Content**: 5 reads, 60bp each

---

### data/sample2.fastq
**Purpose**: Second test sample
**Size**: ~400 bytes
**Format**: FASTQ
**Content**: 4 reads, 60bp each

---

### data/sample3.fastq
**Purpose**: Third test sample
**Size**: ~400 bytes
**Format**: FASTQ
**Content**: 4 reads, 60bp each

**Note**: These are tiny synthetic files designed for quick testing. Real FASTQ files are typically 1-50 GB.

---

## Module Example Files

### modules/nf-core/fastqc/main.nf
**Purpose**: Example nf-core module structure
**Size**: ~1 KB
**Contents**:
- Process definition following nf-core standards
- Meta map input pattern
- Configurable arguments via task.ext
- Stub block for testing

**Demonstrates**:
- nf-core naming conventions
- Label and tag usage
- Process configuration
- Testing scaffold

---

### modules/nf-core/fastqc/environment.yml
**Purpose**: Conda/container dependencies
**Size**: ~200 bytes
**Contents**:
- Conda channels
- Tool dependencies with versions

**Used by**: Seqera Containers/Wave for automatic container building

---

### modules/nf-core/fastqc/meta.yml
**Purpose**: Module metadata
**Size**: ~1 KB
**Contents**:
- Tool description
- Input/output specifications
- Documentation links
- Author information

**Used by**: nf-core documentation system and module browser

---

### environment.yml
**Purpose**: Standalone example for Exercise 3
**Size**: ~150 bytes
**Contents**: FastQC conda environment definition

---

## Testing and Validation

### test_session5.sh
**Purpose**: Automated testing script
**Size**: ~7 KB
**Language**: Bash
**Requirements**: Nextflow, Docker or Singularity

**Features**:
- Prerequisite checking
- Automated workflow execution
- Output validation
- Resume functionality testing
- Module structure validation
- Colored output and reporting

**Run with**:
```bash
chmod +x test_session5.sh
./test_session5.sh
```

**Tests Performed**:
1. Prerequisite checks (Nextflow, Docker, Singularity)
2. Basic container workflow
3. Multi-profile workflow
4. Resume functionality
5. Module structure validation
6. Data file validation

---

## Directory Structure Overview

```
session-5-containers/
├── README.md                      # Main learning document (start here)
├── QUICKSTART.md                  # Fast-track commands
├── EXPECTED_OUTPUTS.md            # Validation guide
├── SOLUTIONS_AND_EXTENSIONS.md    # Advanced patterns
├── SESSION_SUMMARY.md             # Learning recap
├── MANIFEST.md                    # This file
│
├── 01_basic_container.nf          # Exercise 1: Basic container
├── 02_multiprofile_container.nf   # Exercise 2: Multi-profile
│
├── nextflow.config                # Basic config (Exercise 1)
├── nextflow_multiprofile.config   # Advanced config (Exercise 2)
├── environment.yml                # Example conda environment
│
├── data/                          # Sample FASTQ files
│   ├── sample1.fastq
│   ├── sample2.fastq
│   └── sample3.fastq
│
├── modules/                       # nf-core module example
│   └── nf-core/
│       └── fastqc/
│           ├── main.nf
│           ├── environment.yml
│           └── meta.yml
│
└── test_session5.sh               # Automated testing script
```

---

## File Size Summary

**Total Package Size**: ~2 MB (includes all documentation and sample data)

**Core Materials**: ~70 KB
- Documentation: ~50 KB
- Workflows: ~5 KB
- Configurations: ~3 KB
- Module example: ~3 KB
- Test script: ~7 KB
- Sample data: ~2 KB

**Generated During Exercises**: ~50-100 MB
- Work directories: ~20 MB
- Container images: ~800 MB (Docker) or ~500 MB (Singularity)
- Results: ~5 MB

---

## Usage Patterns

### For First-Time Learners
1. Read **README.md** thoroughly
2. Run exercises in order (01 → 02 → 03)
3. Use **EXPECTED_OUTPUTS.md** to validate
4. Review **SESSION_SUMMARY.md** for consolidation

### For Quick Reference
1. Use **QUICKSTART.md** for commands
2. Run workflows directly
3. Check **EXPECTED_OUTPUTS.md** if issues arise

### For Advanced Users
1. Skim **README.md** for new patterns
2. Try **SOLUTIONS_AND_EXTENSIONS.md** challenges
3. Adapt workflows for your use case

### For Testing/Validation
1. Run **test_session5.sh**
2. Review automated test results
3. Manually verify outputs

---

## Learning Path

```
START → README.md (concepts) → 01_basic_container.nf → EXPECTED_OUTPUTS.md
                                        ↓
                            02_multiprofile_container.nf → EXPECTED_OUTPUTS.md
                                        ↓
                            modules/ exploration → SESSION_SUMMARY.md
                                        ↓
                            SOLUTIONS_AND_EXTENSIONS.md → Practice
```

---

## Container Images Used

This session uses the following container images:

1. **biocontainers/fastqc:v0.11.9_cv8**
   - Registry: Docker Hub
   - Size: ~350 MB
   - Purpose: FASTQ quality control

2. **biocontainers/seqtk:v1.3-1-deb_cv1**
   - Registry: Docker Hub
   - Size: ~150 MB
   - Purpose: FASTQ manipulation

3. **quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0**
   - Registry: Quay.io
   - Size: ~300 MB
   - Purpose: QC report aggregation

**Total**: ~800 MB of container images

---

## Key Concepts by File

| Concept | Primary File | Supporting Files |
|---------|--------------|------------------|
| Container basics | README.md | 01_basic_container.nf |
| Container directive | 01_basic_container.nf | nextflow.config |
| Profile configuration | nextflow_multiprofile.config | 02_multiprofile_container.nf |
| Multi-container workflows | 02_multiprofile_container.nf | README.md |
| nf-core module structure | modules/nf-core/fastqc/ | README.md |
| Seqera Containers | environment.yml | README.md |
| Testing | test_session5.sh | EXPECTED_OUTPUTS.md |

---

## Prerequisites by Exercise

### Exercise 1
- Nextflow 25.04.0+
- Docker OR Singularity
- 1 GB free disk space

### Exercise 2
- All of Exercise 1
- 2 GB free disk space
- Internet connection for image pulls

### Exercise 3
- Text editor or IDE
- Understanding of YAML format
- Familiarity with conda (helpful but not required)

---

## Time Investment Guide

| Activity | Estimated Time |
|----------|----------------|
| Reading README.md | 20 minutes |
| Exercise 1 | 15 minutes |
| Exercise 2 | 25 minutes |
| Exercise 3 exploration | 10 minutes |
| SOLUTIONS reading | 15 minutes |
| **Total Session** | **85 minutes** |

*First run includes container image pulls which add 5-10 minutes*

---

## Related Sessions

**Prerequisites**: Sessions 1-4 completed
**Follows**: Session 4 (Modules)
**Prepares for**: Session 6 (Configuration)

**Session Flow**:
```
Session 4 (Modules) → Session 5 (Containers) → Session 6 (Configuration)
```

---

## Troubleshooting Quick Reference

| Issue | Check File | Section |
|-------|------------|---------|
| Workflow fails | EXPECTED_OUTPUTS.md | Common Issues |
| Container errors | README.md | Debugging Tips |
| Config problems | QUICKSTART.md | Troubleshooting Quick Fixes |
| Advanced patterns | SOLUTIONS_AND_EXTENSIONS.md | Extension 1-10 |
| Testing failures | test_session5.sh | Built-in error messages |

---

## Modification Guide

To adapt these materials:

1. **Change container versions**: Update container tags in workflow files
2. **Add new tools**: Follow pattern in SOLUTIONS_AND_EXTENSIONS.md
3. **Modify resources**: Edit nextflow_multiprofile.config
4. **Add new samples**: Create new .fastq files in data/
5. **Create new profiles**: Add to nextflow_multiprofile.config profiles block

---

## Version History

- **v1.0** (February 2026): Initial release
  - Aligned with Nextflow 25.04.6
  - Following 2026 curriculum standards
  - Lowercase `channel` syntax
  - Explicit closure parameters
  - Modern nf-core patterns

---

**This manifest serves as your complete reference for navigating Session 5 materials. Happy learning!** 🚀
