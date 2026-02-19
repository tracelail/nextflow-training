#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 5: Illumina Filename Parser (CHALLENGE)
 *
 * Learning objectives:
 * - Parse complex Illumina FASTQ filename format
 * - Extract all components: sample name, S-number, lane, read, chunk
 * - Build comprehensive meta map
 *
 * Illumina filename format:
 *   SampleName_S1_L001_R1_001.fastq.gz
 *   ├─────────┬──┬────┬──┬───┬────────
 *   │         │  │    │  │   └─ Chunk (001)
 *   │         │  │    │  └───── Read (R1/R2)
 *   │         │  │    └──────── Lane (L001-L008)
 *   │         │  └───────────── Sample number (S1-S999)
 *   │         └──────────────── Sample name
 *   └────────────────────────── Base identifier
 *
 * YOUR TASK: Complete the parseIlluminaFilename() function below
 *
 * Run: nextflow run 05_illumina_parser.nf
 */

// ===========================================
// YOUR CHALLENGE: Complete this function
// ===========================================

def parseIlluminaFilename(filename) {
    /*
     * Parse an Illumina-style FASTQ filename into a meta map
     *
     * Input format: SampleName_S1_L001_R1_001.fastq.gz
     *
     * Output format:
     * [
     *   id: 'SampleName',
     *   sample_number: 'S1',
     *   lane: 'L001',
     *   read: 'R1',
     *   chunk: '001'
     * ]
     *
     * HINTS:
     * 1. Remove the .fastq.gz extension first
     * 2. Use tokenize('_') to split into parts
     * 3. The pattern is always: NAME_SNUM_LANE_READ_CHUNK
     * 4. Use 'def' for all local variables
     * 5. Return a Map with the keys shown above
     */

    // TODO: Remove extension
    def base = filename - '.fastq.gz'

    // TODO: Split into components
    def parts = base.tokenize('_')

    // TODO: Build meta map
    def meta = [
        id: parts[0],
        sample_number: parts[1],
        lane: parts[2],
        read: parts[3],
        chunk: parts[4]
    ]

    // TODO: Return the meta map
    return meta
}


// ===========================================
// Test Cases - DO NOT MODIFY
// ===========================================

workflow {
    println "\n=== Testing Illumina Filename Parser ==="
    println "Format: SampleName_S#_L###_R#_###.fastq.gz"
    println ""

    def test_files = [
        'PatientA_S1_L001_R1_001.fastq.gz',
        'TumorB_S12_L002_R2_001.fastq.gz',
        'Control_S5_L001_R1_001.fastq.gz'
    ]

    test_files.each { filename ->
        println "Parsing: ${filename}"
        def meta = parseIlluminaFilename(filename)
        println "  Meta: ${meta}"
        println ""
    }

    // Additional validation tests
    println "\n=== Validation Tests ==="

    // Test 1: Check all required keys exist
    def sample_meta = parseIlluminaFilename('Sample_S1_L001_R1_001.fastq.gz')
    def required_keys = ['id', 'sample_number', 'lane', 'read', 'chunk']
    def missing_keys = required_keys.findAll { key -> !sample_meta.containsKey(key) }

    if (missing_keys.size() > 0) {
        println "❌ FAILED: Missing keys: ${missing_keys}"
    } else {
        println "✅ PASSED: All required keys present"
    }

    // Test 2: Check sample ID is extracted correctly
    if (sample_meta.id == 'Sample') {
        println "✅ PASSED: Sample ID correctly extracted"
    } else {
        println "❌ FAILED: Sample ID should be 'Sample', got '${sample_meta.id}'"
    }

    // Test 3: Check lane format preserved
    if (sample_meta.lane == 'L001') {
        println "✅ PASSED: Lane format preserved"
    } else {
        println "❌ FAILED: Lane should be 'L001', got '${sample_meta.lane}'"
    }

    // Test 4: Check read number preserved
    if (sample_meta.read == 'R1') {
        println "✅ PASSED: Read number preserved"
    } else {
        println "❌ FAILED: Read should be 'R1', got '${sample_meta.read}'"
    }

    // Test 5: Paired-end read detection
    println "\n=== Paired-End Detection Test ==="
    def r1_file = 'Patient_S1_L001_R1_001.fastq.gz'
    def r2_file = 'Patient_S1_L001_R2_001.fastq.gz'

    def r1_meta = parseIlluminaFilename(r1_file)
    def r2_meta = parseIlluminaFilename(r2_file)

    if (r1_meta.read == 'R1' && r2_meta.read == 'R2') {
        println "✅ PASSED: Can distinguish R1 from R2"
    } else {
        println "❌ FAILED: Cannot properly identify read pairs"
    }

    // Final summary
    println "\n=== Summary ==="
    println "When all tests pass, you've successfully completed the challenge!"
    println "Compare your solution with: solutions/05_illumina_parser_solution.nf"
}

/*
 * Expected Output (when correctly implemented):
 *
 * === Testing Illumina Filename Parser ===
 * Format: SampleName_S#_L###_R#_###.fastq.gz
 *
 * Parsing: PatientA_S1_L001_R1_001.fastq.gz
 *   Meta: [id:PatientA, sample_number:S1, lane:L001, read:R1, chunk:001]
 *
 * Parsing: TumorB_S12_L002_R2_001.fastq.gz
 *   Meta: [id:TumorB, sample_number:S12, lane:L002, read:R2, chunk:001]
 *
 * Parsing: Control_S5_L001_R1_001.fastq.gz
 *   Meta: [id:Control, sample_number:S5, lane:L001, read:R1, chunk:001]
 *
 *
 * === Validation Tests ===
 * ✅ PASSED: All required keys present
 * ✅ PASSED: Sample ID correctly extracted
 * ✅ PASSED: Lane format preserved
 * ✅ PASSED: Read number preserved
 *
 * === Paired-End Detection Test ===
 * ✅ PASSED: Can distinguish R1 from R2
 *
 * === Summary ===
 * When all tests pass, you've successfully completed the challenge!
 * Compare your solution with: solutions/05_illumina_parser_solution.nf
 */
