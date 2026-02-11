# Session 4 - Quick Start

## Get Started in 3 Steps

1. **Extract the materials to your training directory:**
   ```bash
   cd ~/nextflow-training
   mkdir -p day-4
   cd day-4
   # Copy all files from this session-4 folder here
   ```

2. **Verify setup:**
   ```bash
   chmod +x setup_session4.sh bin/analyze.sh
   ./setup_session4.sh
   ```

3. **Start learning:**
   ```bash
   # Read the README first
   cat README.md
   
   # Then follow the testing guide
   cat TESTING_GUIDE.md
   
   # Or jump right in:
   nextflow run monolithic.nf
   nextflow run main.nf
   ```

## File Guide

- **README.md** - Main learning guide with concepts and exercises
- **TESTING_GUIDE.md** - Detailed step-by-step walkthrough
- **EXPECTED_OUTPUTS.md** - Verify your results
- **PROJECT_STRUCTURE.md** - Understanding the organization
- **setup_session4.sh** - Verification script

## Core Exercise Files

- **monolithic.nf** - Starting point (all in one file)
- **main.nf** - Modular version (basic exercise)
- **exercise_02.nf** - Process aliasing (intermediate)
- **exercise_03.nf** - bin/ directory usage (challenge)

## Support Files

- **modules/local/*.nf** - Reusable process modules
- **bin/analyze.sh** - Helper script for analysis

Happy learning! 🚀
