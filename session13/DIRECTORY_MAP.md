# Session 13 Materials — Directory Map

```
session13/
│
├── README.md                          ← START HERE — full session guide
├── CHEATSHEET.md                      ← Quick reference for commands
│
├── sample_data/
│   ├── samplesheet.csv                ← Paired-end samplesheet (3 samples)
│   ├── samplesheet_single_end.csv     ← Single-end variant for comparison
│   └── reads/
│       ├── CONTROL_REP1_1.fastq.gz    ← Synthetic reads (100 reads each)
│       ├── CONTROL_REP1_2.fastq.gz
│       ├── CONTROL_REP2_1.fastq.gz
│       ├── CONTROL_REP2_2.fastq.gz
│       ├── TREATMENT_REP1_1.fastq.gz
│       └── TREATMENT_REP1_2.fastq.gz
│
├── configs/
│   ├── nf-params.json                 ← Params file for Exercise 2
│   ├── my_custom.config               ← Custom Nextflow config for Exercise 3
│   └── demo_params_skeleton.yml       ← All parameters with defaults/descriptions
│
├── scripts/
│   ├── generate_test_reads.py         ← Python script that created the FASTQ files
│   ├── run_exercise1.sh               ← Exercise 1 run command with comments
│   ├── run_exercise2.sh               ← Exercise 2 run command with comments
│   ├── run_exercise3.sh               ← Exercise 3 download + run script
│   └── explore_pipeline.sh           ← Pipeline code exploration helper
│
└── expected_outputs/
    └── EXPECTED_OUTPUTS.md            ← What to expect from each exercise
```

## How to use these materials

1. Read `README.md` from top to bottom before running anything
2. For each exercise, try to write the command yourself before looking at the scripts
3. The scripts in `scripts/` are annotated reference implementations — use them to verify your approach
4. If something goes wrong, check `expected_outputs/EXPECTED_OUTPUTS.md` for the correct output and the debugging section of `README.md`

## Working directory setup

All commands assume you run from **inside the session13/ directory**:

```bash
cd ~/projects/nextflow-training/session13
conda activate nf-core
```

The `sample_data/` paths in `samplesheet.csv` are relative to this directory.
