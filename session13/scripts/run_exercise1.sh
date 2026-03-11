#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_exercise1.sh
# Session 13 — Exercise 1 (Basic)
# Runs nf-core/demo with the built-in test profile.
#
# Usage:
#   bash scripts/run_exercise1.sh
#
# Prerequisites:
#   - Nextflow >= 25.10.2 on PATH (or NXF_VER exported)
#   - Docker running, OR change PROFILE to "singularity,test"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PIPELINE="nf-core/demo"
REVISION="1.1.0"
PROFILE="docker,test"
OUTDIR="results_exercise1"

echo "============================================================"
echo "  Session 13 — Exercise 1: Run with test profile"
echo "  Pipeline : ${PIPELINE}"
echo "  Version  : ${REVISION}"
echo "  Profile  : ${PROFILE}"
echo "  Output   : ${OUTDIR}"
echo "============================================================"
echo ""

# Reminder: -profile uses SINGLE hyphen (Nextflow flag)
#           --outdir uses DOUBLE hyphen (pipeline parameter)
nextflow run "${PIPELINE}" \
    -r "${REVISION}" \
    -profile "${PROFILE}" \
    --outdir "${OUTDIR}"

echo ""
echo "============================================================"
echo "  Run complete. Outputs in: ${OUTDIR}/"
echo ""
echo "  Key outputs to examine:"
echo "    ${OUTDIR}/multiqc/multiqc_report.html"
echo "    ${OUTDIR}/pipeline_info/execution_report.html"
echo "    ${OUTDIR}/pipeline_info/execution_trace.txt"
echo "============================================================"
