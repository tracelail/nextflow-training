#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 4: Filename Parsing (Intermediate)
 *
 * Learning objectives:
 * - Parse realistic bioinformatics filenames
 * - Extract sample ID, condition, read number
 * - Build structured meta maps
 * - Handle paired-end reads
 *
 * Run: nextflow run 04_filename_parsing.nf
 */

// ===========================================
// FUNCTIONS - Defined at top level
// ===========================================

// Define a function to parse standard filename format
def parseSimpleFilename(filename) {
    // Remove extension
    def base = filename - '.fastq.gz'

    // Split into components
    def parts = base.tokenize('_')

    // Build and return meta map
    def meta = [
        id: parts[0],
        condition: parts[1],
        read: parts[2]
    ]

    return meta
}

def parseComplexFilename(filename) {
    def base = filename - '.fastq.gz'
    def parts = base.tokenize('_')

    def meta = [
        patient: parts[0],
        timepoint: parts[1],
        replicate: parts[2],
        condition: parts[3],
        read: parts[4]
    ]

    return meta
}

// Sometimes you want a composite ID that uniquely identifies a sample
def buildSampleId(meta) {
    return "${meta.patient}_${meta.timepoint}_${meta.replicate}"
}

def parseSafeFilename(filename) {
    // Check if file has correct extension
    if (!filename.endsWith('.fastq.gz')) {
        println "  WARNING: Unexpected file extension for ${filename}"
        return null
    }

    def base = filename - '.fastq.gz'
    def parts = base.tokenize('_')

    // Validate we have enough parts
    if (parts.size() < 3) {
        println "  ERROR: Not enough components in ${filename}"
        return null
    }

    // Build meta with validation
    def meta = [
        id: parts[0],
        condition: parts[1],
        read: parts[2]
    ]

    // Validate read number
    if (!(meta.read in ['R1', 'R2'])) {
        println "  WARNING: Unexpected read number ${meta.read} in ${filename}"
    }

    return meta
}

def parseFromPath(filepath) {
    // Extract filename from full path
    def filename = filepath.split('/').last()

    // Parse the filename
    def meta = parseSimpleFilename(filename)

    // Add the full path to meta
    def full_meta = meta + [filepath: filepath]

    return full_meta
}

// ===========================================
// WORKFLOW - Uses the functions defined above
// ===========================================

workflow {

    // ===========================================
    // PART 1: Basic Filename Parsing
    // ===========================================

    println "\n=== PART 1: Basic Filename Parsing ==="

    def simple_file = "sample1_tumor_R1.fastq.gz"
    println "Parsing: ${simple_file}"

    // Step 1: Remove extension
    def base = simple_file - '.fastq.gz'
    println "  Base name: ${base}"

    // Step 2: Split into parts
    def parts = base.tokenize('_')
    println "  Parts: ${parts}"

    // Step 3: Extract components
    def sample_id = parts[0]
    def condition = parts[1]
    def read = parts[2]

    println "  Sample ID: ${sample_id}"
    println "  Condition: ${condition}"
    println "  Read: ${read}"

    // Step 4: Build meta map
    def meta = [
        id: sample_id,
        condition: condition,
        read: read
    ]
    println "  Meta map: ${meta}"


    // ===========================================
    // PART 2: Function for Reusable Parsing
    // ===========================================

    println "\n=== PART 2: Reusable Parsing Function ==="


    // Test the function on multiple files
    def test_files = [
        'sample1_tumor_R1.fastq.gz',
        'sample2_normal_R2.fastq.gz',
        'sample3_tumor_R1.fastq.gz'
    ]

    test_files.each { filename ->
        def meta_result = parseSimpleFilename(filename)
        println "Parsing: ${filename}"
        println "  Meta: ${meta_result}"
        println ""
    }


    // ===========================================
    // PART 3: Handling Paired-End Reads
    // ===========================================

    println "\n=== PART 3: Paired-End Read Handling ==="

    def paired_files = [
        'patientA_tumor_R1.fastq.gz',
        'patientA_tumor_R2.fastq.gz',
        'patientB_normal_R1.fastq.gz',
        'patientB_normal_R2.fastq.gz'
    ]

    // Parse all files and identify pairs
    println "All files with metadata:"
    paired_files.each { filename ->
        def meta_parsed = parseSimpleFilename(filename)
        println "  ${meta_parsed.id} (${meta_parsed.condition}): Read ${meta_parsed.read}"
    }

    // Group by sample ID to identify pairs
    println "\nGrouping by sample:"
    def by_sample = paired_files.groupBy { filename ->
        def meta_grouped = parseSimpleFilename(filename)
        meta_grouped.id
    }

    by_sample.each { sample_name, files ->
        println "  ${sample_name}: ${files.size()} files"
        files.each { f -> println "    - ${f}" }
    }


    // ===========================================
    // PART 4: More Complex Filename Pattern
    // ===========================================

    println "\n=== PART 4: Complex Filename Pattern ==="

    // Pattern: PatientID_TimePoint_Replicate_Condition_ReadNum.fastq.gz
    // Example: P001_T0_Rep1_Tumor_R1.fastq.gz



    def complex_files = [
        'P001_T0_Rep1_Tumor_R1.fastq.gz',
        'P001_T0_Rep1_Tumor_R2.fastq.gz',
        'P001_T1_Rep1_Normal_R1.fastq.gz',
        'P002_T0_Rep2_Tumor_R1.fastq.gz'
    ]

    println "Complex filename parsing:"
    complex_files.each { filename ->
        def meta_complex = parseComplexFilename(filename)
        println "  ${filename}"
        println "    Patient: ${meta_complex.patient}, Time: ${meta_complex.timepoint}, Rep: ${meta_complex.replicate}"
        println "    Condition: ${meta_complex.condition}, Read: ${meta_complex.read}"
    }


    // ===========================================
    // PART 5: Building Sample ID from Components
    // ===========================================

    println "\n=== PART 5: Composite Sample IDs ==="

    println "Creating composite sample IDs:"
    complex_files.each { filename ->
        def meta_component = parseComplexFilename(filename)
        def sample_idd = buildSampleId(meta_component)
        def extended_meta = meta_component + [id: sample_idd]
        println "  filename: ${filename}"
        println "  meta component: ${meta_component}"
        println "  sample id: ${sample_idd}"

        println "    Composite ID: ${extended_meta.id}"
        println "    Full meta: ${extended_meta}"
    }


    // ===========================================
    // PART 6: Error Handling and Validation
    // ===========================================

    println "\n=== PART 6: Error Handling ==="

    // Test with good and bad filenames
    def mixed_files = [
        'sample1_tumor_R1.fastq.gz',      // Good
        'sample2_normal_R3.fastq.gz',     // Warning: R3
        'sample3_tumor.fq.gz',             // Error: wrong extension
        'sample4_R1.fastq.gz'              // Error: not enough parts
    ]

    println "Testing validation:"
    mixed_files.each { filename ->
        println "\n  Processing: ${filename}"
        def meta_safe = parseSafeFilename(filename)
        if (meta_safe) {
            println "    Success: ${meta_safe}"
        } else {
            println "    Skipped due to errors"
        }
    }


    // ===========================================
    // PART 7: Real-World Pattern - Combining with Paths
    // ===========================================

    println "\n\n=== PART 7: Filename + Path Handling ==="

    // In real Nextflow, you'd have Path objects, not strings
    // Simulate this with a function that extracts just the filename

    def file_paths = [
        '/data/raw/sample1_tumor_R1.fastq.gz',
        '/data/raw/sample1_tumor_R2.fastq.gz'
    ]

    println "Parsing files with paths:"
    file_paths.each { path ->
        def meta_path = parseFromPath(path)
        println "  File: ${meta_path.filepath}"
        println "    ID: ${meta_path.id}, Condition: ${meta_path.condition}, Read: ${meta_path.read}"
    }
}

/*
 * Expected Output:
 *
 * === PART 1: Basic Filename Parsing ===
 * Parsing: sample1_tumor_R1.fastq.gz
 *   Base name: sample1_tumor_R1
 *   Parts: [sample1, tumor, R1]
 *   Sample ID: sample1
 *   Condition: tumor
 *   Read: R1
 *   Meta map: [id:sample1, condition:tumor, read:R1]
 *
 * === PART 2: Reusable Parsing Function ===
 * Parsing: sample1_tumor_R1.fastq.gz
 *   Meta: [id:sample1, condition:tumor, read:R1]
 *
 * Parsing: sample2_normal_R2.fastq.gz
 *   Meta: [id:sample2, condition:normal, read:R2]
 *
 * Parsing: sample3_tumor_R1.fastq.gz
 *   Meta: [id:sample3, condition:tumor, read:R1]
 *
 * === PART 3: Paired-End Read Handling ===
 * All files with metadata:
 *   patientA (tumor): Read R1
 *   patientA (tumor): Read R2
 *   patientB (normal): Read R1
 *   patientB (normal): Read R2
 *
 * Grouping by sample:
 *   patientA: 2 files
 *     - patientA_tumor_R1.fastq.gz
 *     - patientA_tumor_R2.fastq.gz
 *   patientB: 2 files
 *     - patientB_normal_R1.fastq.gz
 *     - patientB_normal_R2.fastq.gz
 *
 * === PART 4: Complex Filename Pattern ===
 * Complex filename parsing:
 *   P001_T0_Rep1_Tumor_R1.fastq.gz
 *     Patient: P001, Time: T0, Rep: Rep1
 *     Condition: Tumor, Read: R1
 *   P001_T0_Rep1_Tumor_R2.fastq.gz
 *     Patient: P001, Time: T0, Rep: Rep1
 *     Condition: Tumor, Read: R2
 *   P001_T1_Rep1_Normal_R1.fastq.gz
 *     Patient: P001, Time: T1, Rep: Rep1
 *     Condition: Normal, Read: R1
 *   P002_T0_Rep2_Tumor_R1.fastq.gz
 *     Patient: P002, Time: T0, Rep: Rep2
 *     Condition: Tumor, Read: R1
 *
 * === PART 5: Composite Sample IDs ===
 * Creating composite sample IDs:
 *   P001_T0_Rep1_Tumor_R1.fastq.gz
 *     Composite ID: P001_T0_Rep1
 *     Full meta: [patient:P001, timepoint:T0, replicate:Rep1, condition:Tumor, read:R1, id:P001_T0_Rep1]
 *   P001_T0_Rep1_Tumor_R2.fastq.gz
 *     Composite ID: P001_T0_Rep1
 *     Full meta: [patient:P001, timepoint:T0, replicate:Rep1, condition:Tumor, read:R2, id:P001_T0_Rep1]
 *   P001_T1_Rep1_Normal_R1.fastq.gz
 *     Composite ID: P001_T1_Rep1
 *     Full meta: [patient:P001, timepoint:T1, replicate:Rep1, condition:Normal, read:R1, id:P001_T1_Rep1]
 *   P002_T0_Rep2_Tumor_R1.fastq.gz
 *     Composite ID: P002_T0_Rep2
 *     Full meta: [patient:P002, timepoint:T0, replicate:Rep2, condition:Tumor, read:R1, id:P002_T0_Rep2]
 *
 * === PART 6: Error Handling ===
 * Testing validation:
 *
 *   Processing: sample1_tumor_R1.fastq.gz
 *     Success: [id:sample1, condition:tumor, read:R1]
 *
 *   Processing: sample2_normal_R3.fastq.gz
 *   WARNING: Unexpected read number R3 in sample2_normal_R3.fastq.gz
 *     Success: [id:sample2, condition:normal, read:R3]
 *
 *   Processing: sample3_tumor.fq.gz
 *   WARNING: Unexpected file extension for sample3_tumor.fq.gz
 *     Skipped due to errors
 *
 *   Processing: sample4_R1.fastq.gz
 *   ERROR: Not enough components in sample4_R1
 *     Skipped due to errors
 *
 *
 * === PART 7: Filename + Path Handling ===
 * Parsing files with paths:
 *   File: /data/raw/sample1_tumor_R1.fastq.gz
 *     ID: sample1, Condition: tumor, Read: R1
 *   File: /data/raw/sample1_tumor_R2.fastq.gz
 *     ID: sample1, Condition: tumor, Read: R2
 */
