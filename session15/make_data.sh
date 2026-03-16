#!/usr/bin/env bash
# Generates tiny synthetic FASTQ files for 4 samples (paired-end)
# Each file has 8 reads — small enough for fast runs, real enough for FastQC
set -euo pipefail

OUTDIR="$(dirname "$0")/data"
mkdir -p "$OUTDIR"

# Reproducible pseudo-random sequences
SEQS=(
  "ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT"
  "TGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCA"
  "AAACCCGGGTTTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT"
  "GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA"
  "TTTTGGGGCCCCAAAAGGGGCCCCAAAATTTTGGGGCCCCAAAATTTTGGGG"
  "ACACACACACACACACACACACACACACACACACACACACACACACACACACACAC"
  "GTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGTGT"
  "CGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGAT"
)
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"

make_fastq() {
  local SAMPLE="$1"
  local READ="$2"
  local FILE="${OUTDIR}/${SAMPLE}_${READ}.fastq"

  > "$FILE"
  for i in {1..8}; do
    SEQ="${SEQS[$((i-1))]}"
    # Trim/pad to 50 bp
    SEQ="${SEQ:0:50}"
    Q="${QUAL:0:50}"
    echo "@${SAMPLE}_${READ}_read${i}" >> "$FILE"
    echo "$SEQ" >> "$FILE"
    echo "+" >> "$FILE"
    echo "$Q" >> "$FILE"
  done

  gzip -f "$FILE"
  echo "Created ${FILE}.gz"
}

for SAMPLE in sample1 sample2 sample3 sample4; do
  make_fastq "$SAMPLE" "R1"
  make_fastq "$SAMPLE" "R2"
done

echo "Done — 8 FASTQ files created in $OUTDIR"
