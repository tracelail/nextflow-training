# Day 2 Training - Quick Start

## Setup

Before starting, make sure you're in the right conda environment:

```bash
cd ~/nextflow-training/day2-operators
conda activate nf-core
```

## Training Structure

Work through exercises in order:
1. `01_view.nf` - Learn to debug with view
2. `02_map.nf` - Transform data
3. `03_map_tuples.nf` - Create tuples
4. Continue through the numbered exercises...

## Running Exercises

```bash
nextflow run 01_view.nf
nextflow run 02_map.nf
# etc.
```

## After Each Run

Clean up work directories:
```bash
nextflow clean -f
rm -rf work/ .nextflow* .nextflow.log*
```

## Challenge

When you reach `challenge.nf`, try to solve it yourself first!
Check `challenge_solution.nf` only after you've tried.

## Reference

See `README.md` for detailed explanations of each exercise.

Happy learning! 🚀
