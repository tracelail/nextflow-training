#!/usr/bin/env nextflow

/*
 * Session 7 - Exercise 3: Closures (Intermediate)
 * 
 * Learning objectives:
 * - Write closures with explicit parameters (2026 strict syntax)
 * - Understand why implicit 'it' is banned
 * - Use collect, findAll, find, any, each
 * - Compare old vs new syntax side-by-side
 * 
 * Run: nextflow run 03_closures.nf
 */

workflow {
    
    // ===========================================
    // PART 1: Old vs New Syntax Comparison
    // ===========================================
    
    println "\n=== PART 1: Old (Implicit 'it') vs New (Explicit Parameter) Syntax ==="
    
    def numbers = [1, 2, 3, 4, 5]
    
    // -------------------------------------------
    // Example 1: Transform with collect (like map)
    // -------------------------------------------
    
    // ❌ OLD SYNTAX (banned in strict mode):
    // def doubled_old = numbers.collect { it * 2 }
    // Problem: 'it' is implicit - not clear what 'it' refers to
    
    // ✅ NEW SYNTAX (required in strict mode):
    def doubled = numbers.collect { n -> n * 2 }
    // Benefit: Explicit parameter name makes code self-documenting
    
    println "\nDoubled numbers: ${doubled}"
    
    
    // -------------------------------------------
    // Example 2: Filter with findAll
    // -------------------------------------------
    
    // ❌ OLD SYNTAX:
    // def evens_old = numbers.findAll { it % 2 == 0 }
    
    // ✅ NEW SYNTAX:
    def evens = numbers.findAll { num -> num % 2 == 0 }
    
    println "Even numbers: ${evens}"
    
    
    // -------------------------------------------
    // Example 3: Find first match
    // -------------------------------------------
    
    // ❌ OLD SYNTAX:
    // def first_large_old = numbers.find { it > 5 }
    
    // ✅ NEW SYNTAX:
    def first_large = numbers.find { value -> value > 5 }
    
    println "First number > 5: ${first_large}"
    
    
    // -------------------------------------------
    // Example 4: Check if any match
    // -------------------------------------------
    
    // ❌ OLD SYNTAX:
    // def has_negative_old = numbers.any { it < 0 }
    
    // ✅ NEW SYNTAX:
    def has_negative = numbers.any { x -> x < 0 }
    
    println "Any negatives? ${has_negative}"
    
    
    // ===========================================
    // PART 2: Closures with Multiple Parameters
    // ===========================================
    
    println "\n=== PART 2: Closure with Multiple Parameters ==="
    
    def samples = [
        [id: 'sample1', type: 'tumor'],
        [id: 'sample2', type: 'normal'],
        [id: 'sample3', type: 'tumor']
    ]
    
    // When working with tuples or maps, you can destructure parameters
    
    // ❌ OLD SYNTAX:
    // samples.each { println "${it.id}: ${it.type}" }
    
    // ✅ NEW SYNTAX - using explicit parameter:
    println "Samples with metadata:"
    samples.each { sample ->
        println "  - ${sample.id}: ${sample.type}"
    }
    
    
    // ===========================================
    // PART 3: Why Explicit Parameters Matter
    // ===========================================
    
    println "\n=== PART 3: Why Explicit Parameters Matter ==="
    
    // Reason 1: Readability in complex operations
    def read_counts = [
        [sample: 'A', reads: 1000000],
        [sample: 'B', reads: 500000],
        [sample: 'C', reads: 2000000]
    ]
    
    // ❌ OLD - hard to read in nested operations:
    // def high_coverage = read_counts
    //     .findAll { it.reads > 750000 }
    //     .collect { it.sample }
    
    // ✅ NEW - explicit names make each step clear:
    def high_coverage = read_counts
        .findAll { entry -> entry.reads > 750000 }
        .collect { entry -> entry.sample }
    
    println "High coverage samples: ${high_coverage}"
    
    
    // Reason 2: Prevents variable shadowing bugs
    println "\n--- Variable Shadowing Example ---"
    
    def outer_value = 10
    
    // ❌ BAD - using 'it' can shadow outer variables in complex closures
    // If you have nested closures, implicit 'it' becomes confusing
    
    // ✅ GOOD - explicit names avoid confusion
    def processed = numbers.collect { num ->
        def temp = num * outer_value  // 'num' is clearly the closure parameter
        temp + 5
    }
    println "Processed: ${processed}"
    
    
    // ===========================================
    // PART 4: Common Closure Patterns
    // ===========================================
    
    println "\n=== PART 4: Common Closure Patterns ==="
    
    def data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    // Pattern 1: collect (transform each element)
    def squares = data.collect { n -> n * n }
    println "Squares: ${squares}"
    
    // Pattern 2: findAll (filter elements)
    def multiples_of_3 = data.findAll { n -> n % 3 == 0 }
    println "Multiples of 3: ${multiples_of_3}"
    
    // Pattern 3: find (first matching element)
    def first_even = data.find { n -> n % 2 == 0 }
    println "First even: ${first_even}"
    
    // Pattern 4: any (check if at least one matches)
    def has_large = data.any { n -> n > 100 }
    println "Has number > 100? ${has_large}"
    
    // Pattern 5: every (check if all match)
    def all_positive = data.every { n -> n > 0 }
    println "All positive? ${all_positive}"
    
    // Pattern 6: sum with transformation
    def sum_of_squares = data.collect { n -> n * n }.sum()
    println "Sum of squares: ${sum_of_squares}"
    
    
    // ===========================================
    // PART 5: Closures in Nextflow Context
    // ===========================================
    
    println "\n=== PART 5: Real Nextflow Examples ==="
    
    // Simulating channel operations (these would be actual channels in a pipeline)
    
    // Example 1: Extract file basenames
    def files = ['sample1.fastq.gz', 'sample2.fastq.gz', 'sample3.fastq.gz']
    
    // ❌ OLD: files.collect { it - '.fastq.gz' }
    // ✅ NEW:
    def basenames = files.collect { filename -> filename - '.fastq.gz' }
    println "Basenames: ${basenames}"
    
    
    // Example 2: Build meta maps from filenames
    def fastq_files = [
        'patientA_R1.fastq.gz',
        'patientA_R2.fastq.gz',
        'patientB_R1.fastq.gz'
    ]
    
    // ❌ OLD: fastq_files.collect { [it.split('_')[0], it] }
    // ✅ NEW:
    def with_meta = fastq_files.collect { filename ->
        def sample_id = filename.split('_')[0]
        [sample_id, filename]
    }
    
    println "Files with metadata:"
    with_meta.each { meta ->
        println "  ${meta[0]}: ${meta[1]}"
    }
    
    
    // Example 3: Filter tumor samples
    def sample_meta = [
        [id: 'A', type: 'tumor', paired: true],
        [id: 'B', type: 'normal', paired: true],
        [id: 'C', type: 'tumor', paired: false]
    ]
    
    // ❌ OLD: sample_meta.findAll { it.type == 'tumor' && it.paired }
    // ✅ NEW:
    def paired_tumors = sample_meta.findAll { meta -> 
        meta.type == 'tumor' && meta.paired 
    }
    
    println "\nPaired tumor samples:"
    paired_tumors.each { meta ->
        println "  ${meta.id}"
    }
    
    
    // ===========================================
    // PART 6: Important Rule - Always Use 'def'
    // ===========================================
    
    println "\n=== PART 6: Always Use 'def' for Local Variables ==="
    
    // ❌ DANGEROUS - without 'def', variable is global (race condition in parallel!)
    println "--- Without 'def' (DANGEROUS) ---"
    def dangerous_result = numbers.collect { n ->
        temp = n * 2  // 'temp' leaks to global scope!
        temp
    }
    println "Result: ${dangerous_result}"
    println "Leaked variable 'temp' is now global: ${temp}"
    
    // ✅ SAFE - with 'def', variable is local to closure
    println "\n--- With 'def' (SAFE) ---"
    def safe_result = numbers.collect { n ->
        def local_temp = n * 2  // 'local_temp' is local to this closure
        local_temp
    }
    println "Result: ${safe_result}"
    // println "This would error: ${local_temp}"  // local_temp doesn't exist here
}

/*
 * Expected Output:
 * 
 * === PART 1: Old (Implicit 'it') vs New (Explicit Parameter) Syntax ===
 * 
 * Doubled numbers: [2, 4, 6, 8, 10]
 * Even numbers: [2, 4]
 * First number > 5: null
 * Any negatives? false
 * 
 * === PART 2: Closure with Multiple Parameters ===
 * Samples with metadata:
 *   - sample1: tumor
 *   - sample2: normal
 *   - sample3: tumor
 * 
 * === PART 3: Why Explicit Parameters Matter ===
 * High coverage samples: [A, C]
 * 
 * --- Variable Shadowing Example ---
 * Processed: [15, 25, 35, 45, 55]
 * 
 * === PART 4: Common Closure Patterns ===
 * Squares: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
 * Multiples of 3: [3, 6, 9]
 * First even: 2
 * Has number > 100? false
 * All positive? true
 * Sum of squares: 385
 * 
 * === PART 5: Real Nextflow Examples ===
 * Basenames: [sample1, sample2, sample3]
 * Files with metadata:
 *   patientA: patientA_R1.fastq.gz
 *   patientA: patientA_R2.fastq.gz
 *   patientB: patientB_R1.fastq.gz
 * 
 * Paired tumor samples:
 *   A
 * 
 * === PART 6: Always Use 'def' for Local Variables ===
 * --- Without 'def' (DANGEROUS) ---
 * Result: [2, 4, 6, 8, 10]
 * Leaked variable 'temp' is now global: 10
 * 
 * --- With 'def' (SAFE) ---
 * Result: [2, 4, 6, 8, 10]
 */
