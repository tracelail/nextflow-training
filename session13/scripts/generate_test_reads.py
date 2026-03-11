#!/usr/bin/env python3
"""
generate_test_reads.py
Generates tiny synthetic FASTQ files for Session 13 training exercises.
These are NOT real biological reads - they are short synthetic sequences
used only to demonstrate the samplesheet format and pipeline structure.

In a real pipeline you would use actual sequencing data.
"""

import gzip
import os
import random

random.seed(42)

BASES = "ACGT"
READ_LENGTH = 50
READS_PER_FILE = 100


def random_seq(length):
    return "".join(random.choice(BASES) for _ in range(length))


def random_qual(length):
    # Quality scores as ASCII (Phred+33), range 'I' to '~' (40-62)
    return "".join(chr(random.randint(73, 104)) for _ in range(length))


def write_fastq_gz(filepath, sample_name, read_num, n_reads):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with gzip.open(filepath, "wt") as fh:
        for i in range(1, n_reads + 1):
            seq = random_seq(READ_LENGTH)
            qual = random_qual(READ_LENGTH)
            fh.write(f"@{sample_name}_R{read_num}_{i}\n")
            fh.write(f"{seq}\n")
            fh.write("+\n")
            fh.write(f"{qual}\n")
    print(f"  Written: {filepath}  ({n_reads} reads)")


samples = [
    "CONTROL_REP1",
    "CONTROL_REP2",
    "TREATMENT_REP1",
]

print("Generating synthetic FASTQ files...")
for sample in samples:
    base = f"sample_data/reads/{sample}"
    write_fastq_gz(f"{base}_1.fastq.gz", sample, 1, READS_PER_FILE)
    write_fastq_gz(f"{base}_2.fastq.gz", sample, 2, READS_PER_FILE)

print("\nDone. Files written to sample_data/reads/")
