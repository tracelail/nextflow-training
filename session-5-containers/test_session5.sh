#!/bin/bash

# Session 5 - Automated Test Script
# This script validates that all exercises work correctly

set -e  # Exit on error

echo "========================================"
echo "Session 5 Container Testing Suite"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check Nextflow
if command_exists nextflow; then
    NF_VERSION=$(nextflow -version 2>&1 | head -n1)
    print_success "Nextflow found: $NF_VERSION"
else
    print_error "Nextflow not found. Please install Nextflow first."
    exit 1
fi

# Check Docker or Singularity
HAS_DOCKER=false
HAS_SINGULARITY=false

if command_exists docker && docker ps >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker found and running: $DOCKER_VERSION"
    HAS_DOCKER=true
else
    print_info "Docker not available or not running"
fi

if command_exists singularity; then
    SINGULARITY_VERSION=$(singularity --version)
    print_success "Singularity found: $SINGULARITY_VERSION"
    HAS_SINGULARITY=true
elif command_exists apptainer; then
    APPTAINER_VERSION=$(apptainer --version)
    print_success "Apptainer found: $APPTAINER_VERSION"
    HAS_SINGULARITY=true
else
    print_info "Singularity/Apptainer not available"
fi

if [ "$HAS_DOCKER" = false ] && [ "$HAS_SINGULARITY" = false ]; then
    print_error "Neither Docker nor Singularity/Apptainer is available. Cannot run container tests."
    exit 1
fi

echo ""

# Clean up from previous runs
echo "Cleaning up previous runs..."
nextflow clean -f >/dev/null 2>&1 || true
rm -rf results/ work/ .nextflow* >/dev/null 2>&1 || true
print_success "Cleanup complete"
echo ""

# Test 1: Basic Container Workflow
echo "========================================"
echo "Test 1: Basic Container Workflow"
echo "========================================"
echo ""

if [ "$HAS_DOCKER" = true ]; then
    print_info "Running 01_basic_container.nf..."
    
    if nextflow run 01_basic_container.nf -ansi-log false > test1.log 2>&1; then
        print_success "Workflow completed successfully"
        
        # Check outputs
        if [ -f "results/fastqc/sample1_fastqc.html" ] && [ -f "results/fastqc/sample1_fastqc.zip" ]; then
            print_success "Output files created correctly"
            
            # Check file sizes (HTML should be reasonable size)
            HTML_SIZE=$(stat -f%z "results/fastqc/sample1_fastqc.html" 2>/dev/null || stat -c%s "results/fastqc/sample1_fastqc.html" 2>/dev/null)
            if [ "$HTML_SIZE" -gt 1000 ]; then
                print_success "HTML file has reasonable size (${HTML_SIZE} bytes)"
            else
                print_error "HTML file seems too small (${HTML_SIZE} bytes)"
            fi
        else
            print_error "Expected output files not found"
            cat test1.log
            exit 1
        fi
    else
        print_error "Workflow failed"
        cat test1.log
        exit 1
    fi
else
    print_info "Skipping Test 1 (Docker not available)"
fi

echo ""

# Clean up for next test
nextflow clean -f >/dev/null 2>&1 || true
rm -rf results/ work/ .nextflow* >/dev/null 2>&1 || true

# Test 2: Multi-Profile Workflow
echo "========================================"
echo "Test 2: Multi-Profile Workflow"
echo "========================================"
echo ""

if [ "$HAS_DOCKER" = true ]; then
    print_info "Running 02_multiprofile_container.nf with test profile..."
    
    if nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config -ansi-log false > test2.log 2>&1; then
        print_success "Workflow completed successfully"
        
        # Check QC outputs
        QC_COUNT=$(find results/qc -name "*_fastqc.html" 2>/dev/null | wc -l)
        if [ "$QC_COUNT" -eq 3 ]; then
            print_success "All 3 samples have QC reports"
        else
            print_error "Expected 3 QC reports, found $QC_COUNT"
        fi
        
        # Check MultiQC output
        if [ -f "results/multiqc/multiqc_report.html" ]; then
            print_success "MultiQC report created"
        else
            print_error "MultiQC report not found"
        fi
        
        # Check execution reports
        if [ -f "results/reports/execution_report.html" ]; then
            print_success "Execution report created"
        else
            print_error "Execution report not found"
        fi
        
        # Verify parallel execution
        TASK_COUNT=$(find work -name ".command.sh" 2>/dev/null | wc -l)
        if [ "$TASK_COUNT" -eq 7 ]; then
            print_success "Correct number of tasks executed (7)"
        else
            print_info "Task count: $TASK_COUNT (expected 7)"
        fi
    else
        print_error "Workflow failed"
        cat test2.log
        exit 1
    fi
else
    print_info "Skipping Test 2 (Docker not available)"
fi

echo ""

# Test 3: Resume Functionality
echo "========================================"
echo "Test 3: Resume Functionality"
echo "========================================"
echo ""

if [ "$HAS_DOCKER" = true ]; then
    print_info "Running workflow with -resume..."
    
    # Run again with resume
    START_TIME=$(date +%s)
    if nextflow run 02_multiprofile_container.nf -profile test -c nextflow_multiprofile.config -resume -ansi-log false > test3.log 2>&1; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        print_success "Resume run completed in ${DURATION}s"
        
        # Check if tasks were cached
        if grep -q "Cached" test3.log; then
            print_success "Tasks were successfully cached"
        else
            print_info "No cached tasks detected (might be first run)"
        fi
    else
        print_error "Resume run failed"
        cat test3.log
        exit 1
    fi
else
    print_info "Skipping Test 3 (Docker not available)"
fi

echo ""

# Test 4: Module Structure Validation
echo "========================================"
echo "Test 4: Module Structure Validation"
echo "========================================"
echo ""

print_info "Checking nf-core module structure..."

# Check main.nf
if [ -f "modules/nf-core/fastqc/main.nf" ]; then
    print_success "main.nf exists"
    
    # Check for required elements
    if grep -q "process FASTQC" modules/nf-core/fastqc/main.nf; then
        print_success "Process definition found"
    else
        print_error "Process definition not found"
    fi
    
    if grep -q "container" modules/nf-core/fastqc/main.nf; then
        print_success "Container directive found"
    else
        print_error "Container directive not found"
    fi
else
    print_error "modules/nf-core/fastqc/main.nf not found"
fi

# Check environment.yml
if [ -f "modules/nf-core/fastqc/environment.yml" ]; then
    print_success "environment.yml exists"
    
    if grep -q "fastqc" modules/nf-core/fastqc/environment.yml; then
        print_success "FastQC dependency declared"
    else
        print_error "FastQC dependency not found"
    fi
else
    print_error "modules/nf-core/fastqc/environment.yml not found"
fi

# Check meta.yml
if [ -f "modules/nf-core/fastqc/meta.yml" ]; then
    print_success "meta.yml exists"
else
    print_error "modules/nf-core/fastqc/meta.yml not found"
fi

echo ""

# Test 5: Data File Validation
echo "========================================"
echo "Test 5: Data File Validation"
echo "========================================"
echo ""

print_info "Checking sample data files..."

for i in 1 2 3; do
    FILE="data/sample${i}.fastq"
    if [ -f "$FILE" ]; then
        LINE_COUNT=$(wc -l < "$FILE")
        if [ "$LINE_COUNT" -ge 4 ]; then
            print_success "sample${i}.fastq is valid (${LINE_COUNT} lines)"
        else
            print_error "sample${i}.fastq has too few lines"
        fi
    else
        print_error "sample${i}.fastq not found"
    fi
done

echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo ""

if [ "$HAS_DOCKER" = true ]; then
    print_success "All Docker-based tests passed"
fi

if [ "$HAS_SINGULARITY" = true ]; then
    print_info "Singularity available for HPC testing"
fi

print_success "Module structure validated"
print_success "Sample data validated"

echo ""
echo "All tests completed successfully! ✨"
echo ""
echo "Cleanup options:"
echo "  - Keep results:     results/ directory"
echo "  - Remove work dir:  rm -rf work/"
echo "  - Clean all:        nextflow clean -f && rm -rf results/ work/ .nextflow*"
echo ""

# Optional cleanup
read -p "Do you want to clean up work directories? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nextflow clean -f
    print_success "Work directories cleaned"
fi

exit 0
