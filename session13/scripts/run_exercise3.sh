#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_exercise3.sh
# Session 13 — Exercise 3 (Challenge)
# Downloads nf-core/demo for offline use and runs with a custom config.
#
# Usage:
#   bash scripts/run_exercise3.sh [singularity|docker|none]
#
# Default container system is 'none' (downloads code only, no containers).
# Change to 'singularity' or 'docker' if you want container images included.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PIPELINE="nf-core/demo"
REVISION="1.1.0"
CONTAINER_SYSTEM="${1:-none}"
DOWNLOAD_DIR="nf-core-demo-offline"

echo "============================================================"
echo "  Session 13 — Exercise 3: Download and explore pipeline"
echo "  Pipeline         : ${PIPELINE}"
echo "  Version          : ${REVISION}"
echo "  Container system : ${CONTAINER_SYSTEM}"
echo "  Download dir     : ${DOWNLOAD_DIR}"
echo "============================================================"
echo ""

# ── Step 1: Download the pipeline ──────────────────────────────────────────
if [ -d "${DOWNLOAD_DIR}" ]; then
    echo "Download directory already exists, skipping download."
    echo "Delete '${DOWNLOAD_DIR}/' and re-run to download fresh."
else
    echo "Downloading pipeline..."
    nf-core pipelines download "${PIPELINE}" \
        --revision "${REVISION}" \
        --container-system "${CONTAINER_SYSTEM}" \
        --compress none \
        --outdir "${DOWNLOAD_DIR}"
fi

echo ""
echo "── Directory structure ───────────────────────────────────────────────"
ls -la "${DOWNLOAD_DIR}/"

echo ""
echo "── Workflow directory ────────────────────────────────────────────────"
ls "${DOWNLOAD_DIR}/workflow/"

echo ""
echo "── nf-core modules installed ─────────────────────────────────────────"
ls "${DOWNLOAD_DIR}/workflow/modules/nf-core/" 2>/dev/null || echo "(no modules directory)"

echo ""
echo "── conf/modules.config (ext.args pattern) ────────────────────────────"
cat "${DOWNLOAD_DIR}/workflow/conf/modules.config"

# ── Step 2: Run with custom config ─────────────────────────────────────────
echo ""
echo "============================================================"
echo "  Running offline pipeline with custom config..."
echo "============================================================"
echo ""

nextflow run "${DOWNLOAD_DIR}/workflow/" \
    -profile docker,test \
    -c configs/my_custom.config \
    --outdir results_exercise3

echo ""
echo "============================================================"
echo "  Exercise 3 complete."
echo ""
echo "  What you've done:"
echo "   1. Downloaded the full pipeline for offline use"
echo "   2. Explored the nf-core directory structure"
echo "   3. Understood the ext.args pattern in conf/modules.config"
echo "   4. Applied a custom config with -c"
echo "============================================================"
