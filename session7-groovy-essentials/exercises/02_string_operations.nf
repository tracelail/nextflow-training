#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 2: String Operations (Basic)
 * 
 * Learning objectives:
 * - String interpolation with GStrings
 * - Tokenizing strings with tokenize()
 * - Removing substrings and extensions
 * - Extracting substrings
 * - Pattern matching
 * 
 * Run: nextflow run 02_string_operations.nf
 */

workflow {
    
    // ===========================================
    // PART 1: String Interpolation
    // ===========================================
    
    println "\n=== PART 1: String Interpolation ==="
    
    def sample_name = "sample1"
    def read_count = 1000000
    
    // Double quotes allow variable interpolation (GString)
    def message1 = "Processing ${sample_name} with ${read_count} reads"
    println message1
    
    // Single quotes create literal strings (no interpolation)
    def message2 = 'Processing ${sample_name} with ${read_count} reads'
    println message2
    
    
    // ===========================================
    // PART 2: Filename Parsing Basics
    // ===========================================
    
    println "\n=== PART 2: Basic Filename Parsing ==="
    
    def filename = "sample1_tumor_R1.fastq.gz"
    println "Original filename: ${filename}"
    
    // Remove file extension with - operator
    def without_extension = filename - '.fastq.gz'
    println "Without extension: ${without_extension}"
    
    // Alternative: remove last 9 characters
    def without_ext_alt = filename[0..-10]  // -10 because .fastq.gz is 9 chars + index
    println "Alternative method: ${without_ext_alt}"
    
    // Tokenize - split string into list
    def parts = without_extension.tokenize('_')
    println "Tokenized parts: ${parts}"
    println "First part (sample ID): ${parts[0]}"
    println "Second part (condition): ${parts[1]}"
    println "Third part (read): ${parts[2]}"
    
    
    // ===========================================
    // PART 3: String Extraction Methods
    // ===========================================
    
    println "\n=== PART 3: String Extraction ==="
    
    def illumina_name = "SampleA_S1_L001_R1_001.fastq.gz"
    
    // take() - get first N characters
    def prefix = illumina_name.take(7)
    println "First 7 characters: ${prefix}"
    
    // drop() - remove first N characters
    def suffix = illumina_name.drop(8)
    println "After dropping 8 chars: ${suffix}"
    
    // Substring with range (negative indices count from end)
    def sample_id = illumina_name[0..6]  // Characters 0 through 6
    println "Sample ID (range): ${sample_id}"
    
    def extension = illumina_name[-9..-1]  // Last 9 characters
    println "Extension: ${extension}"
    
    
    // ===========================================
    // PART 4: Pattern Matching
    // ===========================================
    
    println "\n=== PART 4: Pattern Matching ==="
    
    def file1 = "patient_A_tumor_R1.fastq.gz"
    def file2 = "patient_A_tumor_R2.fastq.gz"
    
    // contains() - simple substring check
    println "${file1} contains 'R1': ${file1.contains('R1')}"
    println "${file2} contains 'R1': ${file2.contains('R1')}"
    
    // startsWith() and endsWith()
    println "${file1} starts with 'patient': ${file1.startsWith('patient')}"
    println "${file1} ends with '.gz': ${file1.endsWith('.gz')}"
    
    // Regex matching with =~ operator
    def read_pattern = file1 =~ /_R(\d)_/
    if (read_pattern) {
        println "Regex matched! Read number: ${read_pattern[0][1]}"
    }
    
    
    // ===========================================
    // PART 5: String Manipulation
    // ===========================================
    
    println "\n=== PART 5: String Manipulation ==="
    
    def raw_name = "  Sample_A_Tumor  "
    
    // trim() - remove leading/trailing whitespace
    def trimmed = raw_name.trim()
    println "Trimmed: '${trimmed}'"
    
    // toLowerCase() and toUpperCase()
    println "Lowercase: ${trimmed.toLowerCase()}"
    println "Uppercase: ${trimmed.toUpperCase()}"
    
    // replace() and replaceAll()
    def fixed = trimmed.replace('_', '-')
    println "Replace underscores: ${fixed}"
    
    def cleaned = "Sample_S123_Data".replaceAll(/_S\d+_/, '_')
    println "Remove S-number: ${cleaned}"
    
    
    // ===========================================
    // PART 6: Practical Example - Parse FASTQ Name
    // ===========================================
    
    println "\n=== PART 6: Practical Example ==="
    
    def fastq_file = "PatientX_Tumor_L002_R1.fastq.gz"
    println "Parsing: ${fastq_file}"
    
    // Remove extension
    def base = fastq_file - '.fastq.gz'
    
    // Split into components
    def components = base.tokenize('_')
    
    // Extract information
    def patient_id = components[0]
    def condition = components[1]
    def lane = components[2]
    def read = components[3]
    
    println "  Patient: ${patient_id}"
    println "  Condition: ${condition}"
    println "  Lane: ${lane}"
    println "  Read: ${read}"
    
    // Build a meta map from parsed components
    def meta = [
        id: patient_id,
        condition: condition.toLowerCase(),
        lane: lane,
        read: read
    ]
    
    println "  Meta map: ${meta}"
    
    
    // ===========================================
    // PART 7: Common Pitfalls
    // ===========================================
    
    println "\n=== PART 7: Common Pitfalls ==="
    
    // ❌ PITFALL 1: Tokenizing with multiple delimiters splits on ANY of them
    def name = "sample_R1.fastq.gz"
    def bad_split = name.tokenize('_.')  // Splits on BOTH _ and .
    println "Bad tokenize: ${bad_split}"  // [sample, R1, fastq, gz] - not what we want!
    
    // ✅ BETTER: Remove extension first, then tokenize
    def good_split = (name - '.fastq.gz').tokenize('_')
    println "Good tokenize: ${good_split}"  // [sample, R1] - correct!
    
    // ❌ PITFALL 2: Forgetting that strings are immutable
    def original = "hello"
    original.toUpperCase()  // This returns a new string but doesn't change 'original'
    println "Original unchanged: ${original}"
    
    // ✅ CORRECT: Assign the result
    def uppercase = original.toUpperCase()
    println "New uppercase string: ${uppercase}"
    
    // ❌ PITFALL 3: Empty parts after tokenize
    def messy = "sample__R1"  // Double underscore
    def messy_parts = messy.tokenize('_')
    println "Tokenize skips empty strings: ${messy_parts}"  // [sample, R1] - empty part removed
    
    // If you need to preserve empty parts, use split() instead
    def messy_split = messy.split('_')
    println "Split preserves empty strings: ${messy_split}"  // [sample, , R1]
}

/*
 * Expected Output:
 * 
 * === PART 1: String Interpolation ===
 * Processing sample1 with 1000000 reads
 * Processing ${sample_name} with ${read_count} reads
 * 
 * === PART 2: Basic Filename Parsing ===
 * Original filename: sample1_tumor_R1.fastq.gz
 * Without extension: sample1_tumor_R1
 * Alternative method: sample1_tumor_R1
 * Tokenized parts: [sample1, tumor, R1]
 * First part (sample ID): sample1
 * Second part (condition): tumor
 * Third part (read): R1
 * 
 * === PART 3: String Extraction ===
 * First 7 characters: SampleA
 * After dropping 8 chars: S1_L001_R1_001.fastq.gz
 * Sample ID (range): SampleA
 * Extension: fastq.gz
 * 
 * === PART 4: Pattern Matching ===
 * patient_A_tumor_R1.fastq.gz contains 'R1': true
 * patient_A_tumor_R2.fastq.gz contains 'R1': false
 * patient_A_tumor_R1.fastq.gz starts with 'patient': true
 * patient_A_tumor_R1.fastq.gz ends with '.gz': true
 * Regex matched! Read number: 1
 * 
 * === PART 5: String Manipulation ===
 * Trimmed: 'Sample_A_Tumor'
 * Lowercase: sample_a_tumor
 * Uppercase: SAMPLE_A_TUMOR
 * Replace underscores: Sample-A-Tumor
 * Remove S-number: Sample_Data
 * 
 * === PART 6: Practical Example ===
 * Parsing: PatientX_Tumor_L002_R1.fastq.gz
 *   Patient: PatientX
 *   Condition: Tumor
 *   Lane: L002
 *   Read: R1
 *   Meta map: [id:PatientX, condition:tumor, lane:L002, read:R1]
 * 
 * === PART 7: Common Pitfalls ===
 * Bad tokenize: [sample, R1, fastq, gz]
 * Good tokenize: [sample, R1]
 * Original unchanged: hello
 * New uppercase string: HELLO
 * Tokenize skips empty strings: [sample, R1]
 * Split preserves empty strings: [sample, , R1]
 */
