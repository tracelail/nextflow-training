#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_exercise2.sh
# Session 13 — Exercise 2 (Intermediate)
# Runs nf-core/demo with a custom samplesheet via a params file.
#
# Usage:
#   bash scripts/run_exercise2.sh
#
# Prerequisites:
#   - Must be run from the session13/ working directory
#   - sample_data/reads/ must contain the synthetic FASTQ files
#     (run: python3 scripts/generate_test_reads.py first if needed)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PIPELINE="nf-core/demo"
REVISION="1.1.0"
PARAMS_FILE="configs/nf-params.json"

echo "============================================================"
echo "  Session 13 — Exercise 2: Run with params file"
echo "  Pipeline   : ${PIPELINE}"
echo "  Version    : ${REVISION}"
echo "  Params     : ${PARAMS_FILE}"
echo "============================================================"
echo ""

# Check synthetic reads exist
if [ ! -f "sample_data/reads/CONTROL_REP1_1.fastq.gz" ]; then
    echo "ERROR: Synthetic reads not found."
    echo "Run first: python3 scripts/generate_test_reads.py"
    exit 1
fi

echo "Samplesheet contents:"
cat sample_data/samplesheet.csv
echo ""

# Note: -params-file (single hyphen) is a Nextflow engine flag.
# It loads the JSON/YAML and applies values as pipeline parameters.
# It is equivalent to passing --input and --outdir directly on the CLI,
# but keeps your run command clean and version-controllable.
nextflow run "${PIPELINE}" \
    -r "${REVISION}" \
    -profile docker \
    -params-file "${PARAMS_FILE}"

echo ""
echo "============================================================"
echo "  Run complete."
echo ""
echo "  Compare output structure with Exercise 1:"
echo "    results_custom/"
echo "    ├── fastqc/           <- Reports for YOUR samples"
echo "    ├── fq/               <- Trimmed FASTQs"
echo "    ├── multiqc/          <- Aggregated QC"
echo "    └── pipeline_info/    <- Execution metadata"
echo "============================================================"
