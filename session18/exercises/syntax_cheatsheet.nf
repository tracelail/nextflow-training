// ============================================================
// Session 18 — syntax_cheatsheet.nf
//
// A runnable reference showing every before/after pattern.
// Run `nextflow lint syntax_cheatsheet.nf` to confirm it is clean.
// Enable `export NXF_SYNTAX_PARSER=v2` before running.
// ============================================================

// ──────────────────────────────────────────────────────────────
// 1. CHANNEL FACTORIES — always lowercase
// ──────────────────────────────────────────────────────────────
//   BEFORE: Channel.of()         Channel.fromPath()
//   AFTER:  channel.of()         channel.fromPath()
//
// Full list of factories:
//   channel.of()            channel.fromList()
//   channel.fromPath()      channel.fromFilePairs()
//   channel.fromSRA()       channel.value()
//   channel.empty()         channel.topic()
//   channel.watchPath()

// ──────────────────────────────────────────────────────────────
// 2. CLOSURES — always explicit parameter name
// ──────────────────────────────────────────────────────────────
//   BEFORE: .map { it.id }
//   AFTER:  .map { sample -> sample.id }
//
//   BEFORE: .filter { it.size() > 0 }
//   AFTER:  .filter { reads -> reads.size() > 0 }
//
//   BEFORE: .view { "value: ${it}" }
//   AFTER:  .view { v -> "value: ${v}" }
//
//   BEFORE: .map { [it[0], it[1]] }
//   AFTER:  .map { item -> [item[0], item[1]] }
//          (or use destructuring: .map { meta, reads -> [meta, reads] })

// ──────────────────────────────────────────────────────────────
// 3. LOOPS — replace with functional operators
// ──────────────────────────────────────────────────────────────
//   BEFORE: for (item in list) { result.add(item.id) }
//   AFTER:  def result = list.collect { item -> item.id }
//
//   BEFORE: for (i = 0; i < list.size(); i++) { ... }
//   AFTER:  list.eachWithIndex { item, idx -> ... }
//
//   Common replacements:
//     for + add        → .collect { }
//     for + condition  → .findAll { }
//     for + single     → .find { }
//     for + aggregate  → .inject(seed) { acc, item -> }
//     while loops      → not needed in Nextflow; use channel operators

// ──────────────────────────────────────────────────────────────
// 4. SWITCH — replace with if/else if/else
// ──────────────────────────────────────────────────────────────
//   BEFORE:
//     switch (tool) {
//         case 'bwa':   return 'bwa mem';  break
//         case 'star':  return 'STAR';     break
//         default:      error 'unknown'
//     }
//
//   AFTER:
//     if (tool == 'bwa')        return 'bwa mem'
//     else if (tool == 'star')  return 'STAR'
//     else                      error 'unknown'

// ──────────────────────────────────────────────────────────────
// 5. IMPORT — use fully qualified class names
// ──────────────────────────────────────────────────────────────
//   BEFORE: import groovy.json.JsonSlurper
//           def json = new JsonSlurper().parseText(text)
//
//   AFTER:  def json = new groovy.json.JsonSlurper().parseText(text)
//
//   Common fully qualified names:
//     groovy.json.JsonSlurper
//     groovy.json.JsonOutput
//     groovy.xml.XmlSlurper
//     java.nio.file.Files
//     java.nio.file.Paths

// ──────────────────────────────────────────────────────────────
// 6. SHELL BLOCK → SCRIPT BLOCK
// ──────────────────────────────────────────────────────────────
//   BEFORE (shell:):
//     !{nextflow_var}    ← Nextflow variable
//      $bash_var         ← Bash variable (no escape needed)
//
//   AFTER (script:):
//     ${nextflow_var}    ← Nextflow variable (same as before)
//      \$bash_var         ← Bash variable (must escape $)
//
//   Example:
//     BEFORE:
//       shell:
//       '''
//       bwa mem -t !{task.cpus} !{reference} !{reads} > !{meta.id}.bam
//       RESULT=$(echo "done")
//       '''
//
//     AFTER:
//       script:
//       def sample_id = meta.id
//       """
//       bwa mem -t ${task.cpus} ${reference} ${reads} > ${sample_id}.bam
//       RESULT=\$(echo "done")
//       """

// ──────────────────────────────────────────────────────────────
// 7. ENV INPUT/OUTPUT — must be quoted
// ──────────────────────────────────────────────────────────────
//   BEFORE: env FOO        (in input: or output: block)
//   AFTER:  env 'FOO'

// ──────────────────────────────────────────────────────────────
// 8. TOP-LEVEL STATEMENTS — must be inside workflow {}
// ──────────────────────────────────────────────────────────────
//   BEFORE (top-level — banned):
//     println "Starting..."
//     params.input = null
//     workflow.onComplete { println "Done!" }
//
//   AFTER:
//     params {
//         input: Path        ← typed params block (new in 25.10)
//     }
//
//     workflow {
//         main:
//         // pipeline logic
//
//         onComplete:         ← new section syntax (25.10)
//         log.info "Done!"
//
//         onError:
//         log.error "Failed!"
//     }

// ──────────────────────────────────────────────────────────────
// 9. TYPED PARAMS BLOCK — new in 25.10
// ──────────────────────────────────────────────────────────────
//   params {
//       input:  Path               // required (no default)
//       outdir: Path = 'results'   // optional (has default)
//       threads: Integer = 4
//       save_all: Boolean = false
//       label:  String = ''
//   }
//
//   Supported types: Path, String, Integer, Float, Boolean
//   Nullable:        input: Path?   (allows null at runtime)

// ──────────────────────────────────────────────────────────────
// 10. TYPE ANNOTATIONS — new in 25.10
// ──────────────────────────────────────────────────────────────
//   Local variables:
//     def count: Integer = 0
//     def label: String  = 'sample'
//
//   Workflow take/emit:
//     workflow MY_WORKFLOW {
//         take:
//         reads:   Channel
//         index:   Path
//
//         emit:
//         results: Channel = PROCESS.out.results
//     }
//
//   Function signatures:
//     def greet(name: String) -> String {
//         return "Hello, ${name}!"
//     }

// ──────────────────────────────────────────────────────────────
// ACTUAL RUNNABLE EXAMPLES (for testing with nextflow lint)
// ──────────────────────────────────────────────────────────────

params {
    greeting: String = 'Hello'
    repeat:   Integer = 3
    outdir:   Path = 'results'
}

process SAY_HELLO {
    tag "${meta_id}"

    input:
    val meta_id
    val message

    output:
    path "${meta_id}_greeting.txt", emit: greetings

    script:
    """
    echo "${message}" > ${meta_id}_greeting.txt
    """

    stub:
    """
    touch ${meta_id}_greeting.txt
    """
}

process COLLECT_GREETINGS {
    input:
    path greetings

    output:
    path "all_greetings.txt", emit: combined

    script:
    """
    cat ${greetings} > all_greetings.txt
    """

    stub:
    """
    touch all_greetings.txt
    """
}

workflow {

    main:
    // ✓ Lowercase channel factory
    names_ch = channel.of('Alice', 'Bob', 'Carol')

    // ✓ Explicit closure parameter
    greetings_ch = names_ch.map { name -> "${params.greeting}, ${name}!" }

    // ✓ No implicit 'it'
    upper_ch = greetings_ch.map { msg -> msg.toUpperCase() }

    // ✓ Functional style instead of for loop
    def repeated = (1..params.repeat).collect { i -> "Run ${i}" }

    SAY_HELLO(
        names_ch,
        upper_ch
    )

    COLLECT_GREETINGS(
        SAY_HELLO.out.greetings.collect()
    )

    // ✓ onComplete: section (25.10 syntax)
    onComplete:
    log.info "Cheatsheet workflow complete! Duration: ${workflow.duration}"

    // ✓ onError: section
    onError:
    log.error "Something went wrong: ${workflow.errorMessage}"
}
