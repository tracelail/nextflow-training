# Session 5: Containers - Getting Started

## 📦 Package Contents

You've downloaded complete materials for **Session 5: Containers - Reproducible Software Environments** from the Nextflow Training Curriculum (2026 Edition).

**Total Files**: 18 files organized in logical structure
**Archive Size**: ~24 KB (compressed), ~100 KB (uncompressed)
**Additional Downloads**: ~800 MB container images (automatic during exercises)

---

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Extract the archive
tar -xzf session-5-containers.tar.gz
cd session-5-containers/

# 2. Check prerequisites
nextflow -version   # Should be 25.04.0+
docker ps           # Should show Docker is running

# 3. Run Exercise 1 (basic container usage)
nextflow run 01_basic_container.nf

# 4. View results
open results/fastqc/sample1_fastqc.html  # macOS
# OR
xdg-open results/fastqc/sample1_fastqc.html  # Linux

# Success! You just ran a containerized workflow.
```

---

## 📚 File Organization

```
session-5-containers/
│
├── START HERE
│   ├── README.md              # Main learning document - READ THIS FIRST
│   └── QUICKSTART.md          # Fast commands for quick testing
│
├── EXERCISES (run in order)
│   ├── 01_basic_container.nf
│   └── 02_multiprofile_container.nf
│
├── CONFIGURATION
│   ├── nextflow.config
│   └── nextflow_multiprofile.config
│
├── SAMPLE DATA
│   └── data/
│       ├── sample1.fastq
│       ├── sample2.fastq
│       └── sample3.fastq
│
├── REFERENCE MATERIALS
│   ├── EXPECTED_OUTPUTS.md     # What you should see
│   ├── SOLUTIONS_AND_EXTENSIONS.md
│   ├── SESSION_SUMMARY.md
│   └── MANIFEST.md
│
├── NF-CORE EXAMPLE
│   └── modules/nf-core/fastqc/
│       ├── main.nf
│       ├── environment.yml
│       └── meta.yml
│
└── TESTING
    └── test_session5.sh        # Automated validation
```

---

## 🎯 Learning Objectives

After this session, you will:

✅ Understand what containers are and why they ensure reproducibility  
✅ Run Nextflow processes inside Docker and Singularity containers  
✅ Configure profile-based container runtime selection  
✅ Work with Biocontainers registry images  
✅ Recognize modern nf-core module patterns  
✅ Debug common container-related issues  

---

## 📖 How to Use These Materials

### Option 1: Full Learning Path (90 minutes)
1. Read **README.md** completely (20 min)
2. Work through Exercise 1 (15 min)
3. Work through Exercise 2 (25 min)
4. Explore module structure (10 min)
5. Read **SESSION_SUMMARY.md** (10 min)
6. Try challenges from **SOLUTIONS_AND_EXTENSIONS.md** (20 min)

### Option 2: Quick Hands-On (30 minutes)
1. Skim **QUICKSTART.md** (5 min)
2. Run both exercises (20 min)
3. Validate with **EXPECTED_OUTPUTS.md** (5 min)

### Option 3: Reference Mode (use as needed)
- Use **README.md** for concept explanations
- Use **QUICKSTART.md** for command reference
- Use **EXPECTED_OUTPUTS.md** for troubleshooting
- Use **MANIFEST.md** for file navigation

---

## ⚙️ Prerequisites

### Required
- **Nextflow**: Version 25.04.0 or later
  ```bash
  curl -s https://get.nextflow.io | bash
  ```

- **Container Runtime**: Docker OR Singularity/Apptainer
  - Docker: https://docs.docker.com/get-docker/
  - Singularity: https://sylabs.io/docs/
  - Apptainer: https://apptainer.org/docs/

### Recommended
- 4 GB RAM available
- 2 GB free disk space (for work directories)
- Stable internet connection (for container image pulls)
- Basic command line familiarity

### Completed Sessions
- Session 1: Hello World
- Session 2: Channels
- Session 3: Multi-step workflows
- Session 4: Modules

---

## 🐛 Common Issues

### "Docker is not running"
```bash
# Start Docker Desktop (macOS/Windows)
# OR
sudo systemctl start docker  # Linux
```

### "Permission denied" errors
✅ The provided configs already fix this with:
```groovy
docker.runOptions = '-u $(id -u):$(id -g)'
```

### "Unable to pull Docker image"
```bash
# Check internet connection
ping google.com

# Try pulling manually
docker pull biocontainers/fastqc:v0.11.9_cv8

# OR use test profile (smaller images)
nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config
```

### More help?
See **EXPECTED_OUTPUTS.md** → "Common Issues and Solutions"

---

## 🧪 Validate Your Setup

Run the automated test suite:
```bash
chmod +x test_session5.sh
./test_session5.sh
```

This will:
- Check prerequisites
- Run all exercises
- Validate outputs
- Report any issues

**Expected runtime**: 5-10 minutes (including image pulls)

---

## 🌟 What Makes This Session Special

### 2026 Best Practices
- ✅ Lowercase `channel` factories (not `Channel`)
- ✅ Explicit closure parameters (not implicit `it`)
- ✅ Modern nf-core module structure
- ✅ Seqera Containers patterns
- ✅ Ready for strict syntax mode

### Production-Ready Patterns
- Container version pinning
- Profile-based configuration
- Error handling
- Resource management
- Report generation

### Real-World Tools
- FastQC: Quality control
- seqtk: Sequence manipulation
- MultiQC: Report aggregation

---

## 🎓 Key Concepts Covered

| Concept | Exercise | File |
|---------|----------|------|
| Container basics | 1 | 01_basic_container.nf |
| Container directive | 1 | README.md Section 3 |
| Multi-container workflows | 2 | 02_multiprofile_container.nf |
| Profile configuration | 2 | nextflow_multiprofile.config |
| nf-core modules | 3 | modules/nf-core/fastqc/ |
| Seqera Containers | 3 | environment.yml |

---

## 🔗 Container Images Used

This session uses official Biocontainers images:

1. **FastQC** (v0.11.9_cv8) - ~350 MB
   - Quality control for sequencing data
   
2. **seqtk** (v1.3-1-deb_cv1) - ~150 MB
   - Toolkit for FASTQ/FASTA manipulation
   
3. **MultiQC** (1.14) - ~300 MB
   - Aggregate QC reports

**Total downloads**: ~800 MB (one-time, cached for reuse)

---

## 📊 Progress Tracking

Track your completion:

- [ ] Extracted and explored package
- [ ] Read README.md learning objectives
- [ ] Ran Exercise 1 successfully
- [ ] Understood container directive
- [ ] Ran Exercise 2 successfully
- [ ] Understood profile configuration
- [ ] Explored nf-core module structure
- [ ] Ran automated tests (optional)
- [ ] Read SESSION_SUMMARY.md
- [ ] Tried at least one extension challenge

**All checked?** Congratulations! You've mastered Session 5. 🎉

---

## 🚦 Next Steps

### Immediate
1. Extract the archive
2. Read README.md
3. Run Exercise 1
4. Celebrate your first containerized workflow! 🎊

### This Session
- Complete Exercise 2
- Explore nf-core module structure
- Try extension challenges

### After This Session
- **Session 6**: Advanced configuration and resource management
- **Session 7**: Groovy essentials for Nextflow
- **Beyond**: Build production pipelines with confidence

---

## 💡 Tips for Success

1. **Don't rush**: Take time to understand concepts, not just run commands
2. **Experiment**: Modify workflows and see what happens
3. **Use docs**: README.md has answers to most questions
4. **Validate**: Check EXPECTED_OUTPUTS.md after each exercise
5. **Ask why**: Understanding "why" is more valuable than memorizing "how"

---

## 🆘 Getting Help

If you encounter issues:

1. Check **EXPECTED_OUTPUTS.md** "Common Issues" section
2. Review **README.md** "Debugging Tips"
3. Inspect work directories: `cat work/*/*/.command.err`
4. Check Nextflow log: `cat .nextflow.log`
5. Run automated tests: `./test_session5.sh`

---

## 🌐 Additional Resources

### Official Documentation
- Nextflow: https://www.nextflow.io/docs/latest/container.html
- Docker: https://docs.docker.com/
- Singularity: https://sylabs.io/docs/

### Container Registries
- Biocontainers: https://biocontainers.pro/
- Docker Hub: https://hub.docker.com/
- Quay.io: https://quay.io/

### nf-core
- Modules: https://nf-co.re/modules
- Guidelines: https://nf-co.re/docs/contributing/modules

---

## 📝 Session Overview

**Session**: 5 of 20  
**Topic**: Containers for reproducibility  
**Difficulty**: ⭐⭐ Intermediate  
**Time**: 60-90 minutes  
**Prerequisites**: Sessions 1-4  
**Prepares for**: Session 6 (Configuration)  

---

## ✨ What You'll Build

By the end of this session, you'll have:

1. A working FastQC quality control pipeline
2. A multi-sample analysis workflow with QC aggregation
3. Configuration supporting Docker and Singularity
4. Understanding of nf-core module structure
5. Foundation for building production pipelines

---

**Ready to start? Begin with README.md!** 📖

**Questions about the materials? Everything is documented - check MANIFEST.md for a complete file guide.**

**Happy learning!** 🚀
