#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# explore_pipeline.sh
# Session 13 — Pipeline exploration helper
#
# After running Exercise 1 (which pulls nf-core/demo from GitHub), use this
# script to systematically explore the cached pipeline code. Run each section
# by commenting/uncommenting the relevant part, or pipe to 'less'.
#
# Usage:
#   bash scripts/explore_pipeline.sh 2>&1 | less
# ─────────────────────────────────────────────────────────────────────────────

CACHED="${HOME}/.nextflow/assets/nf-core/demo"

if [ ! -d "${CACHED}" ]; then
    echo "Pipeline not yet cached. Run Exercise 1 first."
    echo "  bash scripts/run_exercise1.sh"
    exit 1
fi

hr() { echo ""; echo "════════════════════════════════════════════════════════"; echo "  $1"; echo "════════════════════════════════════════════════════════"; echo ""; }

hr "TOP-LEVEL FILES"
ls -la "${CACHED}/"

hr "main.nf — the entry point"
cat "${CACHED}/main.nf"

hr "nextflow.config — profiles and default params"
cat "${CACHED}/nextflow.config"

hr "conf/test.config — the test profile"
cat "${CACHED}/conf/test.config"

hr "conf/base.config — default resource labels"
cat "${CACHED}/conf/base.config"

hr "conf/modules.config — ext.args for each process"
cat "${CACHED}/conf/modules.config"

hr "workflows/demo.nf — the main workflow logic"
cat "${CACHED}/workflows/demo.nf"

hr "modules/nf-core/ — installed community modules"
ls "${CACHED}/modules/nf-core/"

hr "modules/nf-core/fastqc/main.nf — a real nf-core module"
cat "${CACHED}/modules/nf-core/fastqc/main.nf"

hr "assets/samplesheet.csv — example samplesheet shipped with the pipeline"
cat "${CACHED}/assets/samplesheet.csv" 2>/dev/null || echo "(not present in this version)"

hr "nextflow_schema.json — parameter definitions (first 60 lines)"
head -60 "${CACHED}/nextflow_schema.json"
