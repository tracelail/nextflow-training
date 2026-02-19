#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 5: Illumina Filename Parser (SOLUTION)
 * 
 * This is the complete solution for the Illumina parser challenge.
 * Compare this with your implementation!
 */

// ===========================================
// SOLUTION: parseIlluminaFilename()
// ===========================================

def parseIlluminaFilename(filename) {
    /*
     * Parse an Illumina-style FASTQ filename into a meta map
     * 
     * Input format: SampleName_S1_L001_R1_001.fastq.gz
     * Output: [id: 'SampleName', sample_number: 'S1', lane: 'L001', read: 'R1', chunk: '001']
     */
    
    // Step 1: Remove the .fastq.gz extension
    def base = filename - '.fastq.gz'
    
    // Step 2: Split into components using underscore delimiter
    def parts = base.tokenize('_')
    
    // Step 3: Extract each component by index
    // Illumina format is always: NAME_SNUM_LANE_READ_CHUNK
    def sample_name = parts[0]
    def sample_num = parts[1]
    def lane = parts[2]
    def read = parts[3]
    def chunk = parts[4]
    
    // Step 4: Build the meta map
    def meta = [
        id: sample_name,
        sample_number: sample_num,
        lane: lane,
        read: read,
        chunk: chunk
    ]
    
    // Step 5: Return the meta map
    return meta
}


// ===========================================
// ALTERNATIVE SOLUTION: More Concise
// ===========================================

def parseIlluminaFilenameConcise(filename) {
    /*
     * A more concise version that directly destructures the parts
     */
    def parts = (filename - '.fastq.gz').tokenize('_')
    
    return [
        id: parts[0],
        sample_number: parts[1],
        lane: parts[2],
        read: parts[3],
        chunk: parts[4]
    ]
}


// ===========================================
// ADVANCED SOLUTION: With Validation
// ===========================================

def parseIlluminaFilenameAdvanced(filename) {
    /*
     * Advanced version with validation and error handling
     */
    
    // Validate extension
    if (!filename.endsWith('.fastq.gz')) {
        println "WARNING: Unexpected extension in ${filename}"
        return null
    }
    
    def base = filename - '.fastq.gz'
    def parts = base.tokenize('_')
    
    // Validate we have exactly 5 components
    if (parts.size() != 5) {
        println "ERROR: Expected 5 components in Illumina filename, got ${parts.size()}"
        return null
    }
    
    // Validate sample number format (should start with 'S')
    if (!parts[1].startsWith('S')) {
        println "WARNING: Sample number doesn't start with 'S': ${parts[1]}"
    }
    
    // Validate lane format (should start with 'L')
    if (!parts[2].startsWith('L')) {
        println "WARNING: Lane doesn't start with 'L': ${parts[2]}"
    }
    
    // Validate read format (should be R1 or R2)
    if (!(parts[3] in ['R1', 'R2'])) {
        println "WARNING: Unexpected read value: ${parts[3]}"
    }
    
    def meta = [
        id: parts[0],
        sample_number: parts[1],
        lane: parts[2],
        read: parts[3],
        chunk: parts[4]
    ]
    
    return meta
}


// ===========================================
// Test Cases
// ===========================================

workflow {
    println "\n=== SOLUTION: Testing Illumina Filename Parser ==="
    println ""
    
    def test_files = [
        'PatientA_S1_L001_R1_001.fastq.gz',
        'TumorB_S12_L002_R2_001.fastq.gz',
        'Control_S5_L001_R1_001.fastq.gz'
    ]
    
    println "--- Basic Solution ---"
    test_files.each { filename ->
        println "Parsing: ${filename}"
        def meta = parseIlluminaFilename(filename)
        println "  Meta: ${meta}"
        println ""
    }
    
    println "\n--- Concise Solution ---"
    test_files.each { filename ->
        def meta = parseIlluminaFilenameConcise(filename)
        println "${filename} -> ${meta}"
    }
    
    println "\n--- Advanced Solution with Validation ---"
    def test_files_mixed = [
        'PatientA_S1_L001_R1_001.fastq.gz',    // Good
        'BadFile_X1_L001_R1_001.fastq.gz',     // Warning: bad sample number
        'Sample_S1_001_R1_001.fastq.gz',       // Warning: bad lane
        'Test_S1_L001_R3_001.fastq.gz'         // Warning: R3 instead of R1/R2
    ]
    
    test_files_mixed.each { filename ->
        println "\nTesting: ${filename}"
        def meta = parseIlluminaFilenameAdvanced(filename)
        if (meta) {
            println "  Result: ${meta}"
        }
    }
    
    
    // ===========================================
    // Practical Example: Processing Paired Reads
    // ===========================================
    
    println "\n\n=== Practical Use Case: Grouping Paired Reads ==="
    
    def all_files = [
        'PatientA_S1_L001_R1_001.fastq.gz',
        'PatientA_S1_L001_R2_001.fastq.gz',
        'PatientB_S2_L001_R1_001.fastq.gz',
        'PatientB_S2_L001_R2_001.fastq.gz',
        'PatientC_S3_L002_R1_001.fastq.gz'
    ]
    
    // Parse all files
    def parsed = all_files.collect { filename ->
        [filename: filename, meta: parseIlluminaFilename(filename)]
    }
    
    // Group by sample ID
    def by_sample = parsed.groupBy { entry -> entry.meta.id }
    
    println "Files grouped by sample:"
    by_sample.each { sample_id, files ->
        println "\n  Sample: ${sample_id}"
        def r1 = files.find { f -> f.meta.read == 'R1' }
        def r2 = files.find { f -> f.meta.read == 'R2' }
        
        if (r1 && r2) {
            println "    ✅ Paired-end (R1 + R2)"
            println "       R1: ${r1.filename}"
            println "       R2: ${r2.filename}"
        } else if (r1) {
            println "    ⚠️  Single-end (R1 only)"
            println "       R1: ${r1.filename}"
        } else {
            println "    ❌ Missing R1 file!"
        }
    }
    
    
    // ===========================================
    // Advanced Pattern: Lane Merging
    // ===========================================
    
    println "\n\n=== Advanced Pattern: Multi-Lane Samples ==="
    
    def multi_lane_files = [
        'Sample1_S1_L001_R1_001.fastq.gz',
        'Sample1_S1_L001_R2_001.fastq.gz',
        'Sample1_S1_L002_R1_001.fastq.gz',
        'Sample1_S1_L002_R2_001.fastq.gz'
    ]
    
    def parsed_multi = multi_lane_files.collect { filename ->
        [filename: filename, meta: parseIlluminaFilename(filename)]
    }
    
    // Group by sample and read (for lane merging)
    def by_sample_read = parsed_multi.groupBy { entry -> 
        "${entry.meta.id}_${entry.meta.read}"
    }
    
    println "Files that need lane merging:"
    by_sample_read.each { key, files ->
        def first_meta = files[0].meta
        println "\n  ${first_meta.id} - ${first_meta.read}:"
        println "    Lanes: ${files.collect { it.meta.lane }.join(', ')}"
        files.each { f ->
            println "      - ${f.filename}"
        }
    }
}

/*
 * Key Learning Points:
 * 
 * 1. Always use 'def' for local variables inside functions
 * 2. Remove extensions before tokenizing to avoid unexpected splits
 * 3. Illumina format is consistent: NAME_SNUM_LANE_READ_CHUNK
 * 4. Index-based extraction works when format is guaranteed
 * 5. Validation catches malformed filenames early
 * 6. Meta maps enable sophisticated grouping and pairing logic
 */
