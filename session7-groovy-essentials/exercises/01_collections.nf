#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 1: Collections (Basic)
 *
 * Learning objectives:
 * - Create and manipulate Lists
 * - Create and manipulate Maps
 * - Understand immutable operations with the + operator
 *
 * Run: nextflow run 01_collections.nf
 */

workflow {

    // ===========================================
    // PART 1: Working with Lists
    // ===========================================

    println "\n=== PART 1: Lists ==="

    // Create a list of sample names
    def samples = ['A', 'B', 'C']

    // Add an element with << operator (mutable operation)
    samples << 'D'

    println "Sample list: ${samples}"
    println "First sample: ${samples[0]}"
    println "Number of samples: ${samples.size()}"
    println "Class of samples: ${samples.class}"    // class is a property, getClass() is a method
    println "Last sample: ${samples[-1]}"  // Negative indexing from end
    println "Range of samples: ${samples[0..2]}"


    // ===========================================
    // PART 2: Working with Maps
    // ===========================================

    println "\n=== PART 2: Maps ==="

    // Create a meta map (key-value pairs)
    def meta = [
        id: 'sample1',
        type: 'tumor',
        patient: 'P001'
    ]

    // Access values by key
    println "Meta map: ${meta}"
    println "Sample type: ${meta.type}"
    println "Patient ID: ${meta['patient']}"  // Alternative syntax

    // Add a new key with direct assignment (mutable - be careful!)
    meta.stage = 'III'
    println "After adding stage: ${meta}"


    // ===========================================
    // PART 3: Immutable Map Operations (IMPORTANT!)
    // ===========================================

    println "\n=== PART 3: Immutable Operations ==="

    // The + operator creates a NEW map without modifying the original
    // This is CRITICAL for parallel execution safety in Nextflow!

    def extended_meta = meta + [batch: 'B1']

    println "Extended meta: ${extended_meta}"
    println "Original meta unchanged: ${meta}"

    // You can also merge multiple keys at once
    def full_meta = meta + [
        batch: 'B1',
        sequencer: 'NovaSeq',
        date: '2026-02-17'
    ]

    println "Full meta: ${full_meta}"


    // ===========================================
    // PART 4: Practical Example - Sample Metadata
    // ===========================================

    println "\n=== PART 4: Practical Example ==="

    // Build a list of sample meta maps
    def sample_list = [
        [id: 'patient_A', type: 'tumor', reads: 1000000],
        [id: 'patient_A', type: 'normal', reads: 1200000],
        [id: 'patient_B', type: 'tumor', reads: 950000]
    ]

    println "Sample collection:"
    sample_list.each { sample ->
        println "  ${sample.id} (${sample.type}): ${sample.reads} reads"
    }

    // Find tumor samples only
    def tumor_samples = sample_list.findAll { sample -> sample.type == 'tumor' }
    println "\nTumor samples only:"
    tumor_samples.each { sample ->
        println "  ${sample.id}: ${sample.reads} reads"
    }

    // large reads
    def large_reads = sample_list.findAll { sample -> sample.reads > 950000 }
    println "\nLarge samples only:"
    large_reads.each { sample ->
        println "  ${sample.id}: ${sample.reads} reads"
    }

    // Group patient
    def group_samples = sample_list.groupBy { sample -> sample.id }
    println "\nId groups:"
    group_samples.each { id, sample ->
        println "  ${id}: ${sample}"
    }



    // ===========================================
    // PART 5: Common Pitfalls
    // ===========================================

    println "\n=== PART 5: Common Pitfalls ==="

    // ❌ PITFALL 1: Direct modification creates mutable state
    def meta1 = [id: 'A']
    meta1.type = 'tumor'  // This works but is mutable
    println "Meta1 after modification: ${meta1}"

    // ✅ BETTER: Use + operator for immutability
    def meta2 = [id: 'B']
    def meta2_extended = meta2 + [type: 'tumor']
    println "Meta2 original: ${meta2}"
    println "Meta2 extended: ${meta2_extended}"

    // ❌ PITFALL 2: Trying to access non-existent keys returns null
    def meta3 = [id: 'C']
    println "Missing key returns null: ${meta3.nonexistent}"

    // ✅ BETTER: Use Elvis operator for default values
    def sample_type = meta3.type ?: 'unknown'
    println "With default value: ${sample_type}"
}

/*
 * Expected Output:
 *
 * === PART 1: Lists ===
 * Sample list: [A, B, C, D]
 * First sample: A
 * Number of samples: 4
 * Last sample: D
 *
 * === PART 2: Maps ===
 * Meta map: [id:sample1, type:tumor, patient:P001]
 * Sample type: tumor
 * Patient ID: P001
 * After adding stage: [id:sample1, type:tumor, patient:P001, stage:III]
 *
 * === PART 3: Immutable Operations ===
 * Extended meta: [id:sample1, type:tumor, patient:P001, stage:III, batch:B1]
 * Original meta unchanged: [id:sample1, type:tumor, patient:P001, stage:III]
 * Full meta: [id:sample1, type:tumor, patient:P001, stage:III, batch:B1, sequencer:NovaSeq, date:2026-02-17]
 *
 * === PART 4: Practical Example ===
 * Sample collection:
 *   patient_A (tumor): 1000000 reads
 *   patient_A (normal): 1200000 reads
 *   patient_B (tumor): 950000 reads
 *
 * Tumor samples only:
 *   patient_A: 1000000 reads
 *   patient_B: 950000 reads
 *
 * === PART 5: Common Pitfalls ===
 * Meta1 after modification: [id:A, type:tumor]
 * Meta2 original: [id:B]
 * Meta2 extended: [id:B, type:tumor]
 * Missing key returns null: null
 * With default value: unknown
 */
