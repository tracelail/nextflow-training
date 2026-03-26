// ============================================================
// Session 18 — violations_checklist.nf
//
// A MINIMAL runnable file that demonstrates every violation
// type you need to find and fix in the starter pipeline.
// This is a teaching aid — run `nextflow lint` on it BEFORE
// and AFTER your edits to validate your understanding.
//
// To use:
//   1. Run: nextflow lint violations_checklist.nf
//      → should show 8+ warnings/errors
//   2. Fix each violation (guided by the comments)
//   3. Run: export NXF_SYNTAX_PARSER=v2
//            nextflow lint violations_checklist.nf
//      → should show 0 warnings, 0 errors
// ============================================================

// VIOLATION 1 — import declaration
// Fix: delete this line; use groovy.json.JsonSlurper directly where needed
import groovy.json.JsonSlurper

// VIOLATION 2 — top-level executable statement
// Fix: move inside workflow {}
println "Top-level println is banned in strict mode"

process DEMO {
    input:
    val greeting
    // VIOLATION 3 — unquoted env output name
    // Fix: env 'MY_ENV'
    env MY_ENV,           emit: env_out
    path "output.txt",    emit: txt_out

    // VIOLATION 4 — shell block
    // Fix: convert to script:, change !{} to ${}, escape Bash $ as \$
    shell:
    '''
    echo "!{greeting}" > output.txt
    MY_ENV=$(echo "value")
    '''
}

// VIOLATION 5 — for loop in a helper function
// Fix: use .collect { item -> item }
def buildList(items) {
    def result = []
    for (item in items) {
        result.add(item.toUpperCase())
    }
    return result
}

// VIOLATION 6 — switch statement
// Fix: use if / else if / else
def getLabel(String level) {
    switch (level) {
        case 'low':    return 'process_low'
        case 'medium': return 'process_medium'
        default:       return 'process_high'
    }
}

workflow {
    // VIOLATION 7 — uppercase Channel factory
    // Fix: channel.of(...)
    greetings = Channel.of('Hello', 'Bonjour', 'Hola')

    // VIOLATION 8 — implicit 'it' (no arrow parameter)
    // Fix: { v -> v.length() } or { greeting -> greeting.length() }
    lengths = greetings.map { it.length() }

    DEMO(greetings)
}

// VIOLATION 9 — top-level workflow handler
// Fix: move inside workflow {} as onComplete: section
workflow.onComplete {
    println "Finished: ${workflow.success}"
}
