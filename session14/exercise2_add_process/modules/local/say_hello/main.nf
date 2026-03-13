/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL MODULE: SAY_HELLO
    ─────────────────────────────────────────────────────────────────────────────────
    Writes a greeting string to a text file.

    TEACHING NOTE: This is a minimal but fully nf-core-compliant local module.
    Compare it to Session 4's simple process and notice what has been added:
      - tag directive (shows sample ID in logs)
      - label directive (maps to resource limits in conf/base.config)
      - when: block (allows conditional skipping via ext.when in modules.config)
      - ext.args and ext.prefix reading pattern
      - versions.yml output (software version reporting)
      - stub: block (fast dry-run for testing without running the real command)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SAY_HELLO {

    // The tag shows up in the Nextflow log beside each task.
    // For a process running on 3 samples, you will see:
    //   [xx/xxxxxx] SAY_HELLO (sample1)
    //   [xx/xxxxxx] SAY_HELLO (sample2)
    //   [xx/xxxxxx] SAY_HELLO (sample3)
    tag "$meta.id"

    // Maps to a withLabel selector in conf/base.config.
    // process_single = 1 CPU, 6 GB memory, 4 h time limit
    label 'process_single'

    // No container needed for pure bash. In a real module you would have:
    // conda "${moduleDir}/environment.yml"
    // container "..."

    input:
    // tuple val(meta)        — a Groovy map: [id:'sample1', ...]
    // val(greeting)          — a plain string: 'Hello'
    //
    // NOTE: In a real bioinformatics pipeline this would typically be:
    //   tuple val(meta), path(reads)
    // where 'reads' is a FASTQ file. We use val(greeting) here because
    // our input is a string, not a file. The meta map pattern is identical.
    tuple val(meta), val(greeting)

    output:
    // emit: txt — named output, accessed as SAY_HELLO.out.txt in the workflow
    tuple val(meta), path("${prefix}.txt"), emit: txt
    // versions.yml — always emitted, used for software version reporting
    path "versions.yml",                    emit: versions

    when:
    // This guard allows modules.config to disable a process entirely:
    //   withName: SAY_HELLO { ext.when = false }
    // When ext.when is not set, the condition is null, and null || true = true.
    task.ext.when == null || task.ext.when

    script:
    // ──────────────────────────────────────────────────────────────────────
    // PATTERN: Read ext.args and ext.prefix from modules.config
    // ──────────────────────────────────────────────────────────────────────
    // task.ext.args is set in conf/modules.config withName: SAY_HELLO block.
    // If not set, it defaults to '' (empty string — no extra arguments).
    def args   = task.ext.args   ?: ''

    // task.ext.prefix overrides the output file name prefix.
    // NOTE: 'prefix' has no 'def' keyword. This is intentional — it needs
    // to be visible to the output: block's path("${prefix}.txt") declaration.
    prefix     = task.ext.prefix ?: "${meta.id}"
    // ──────────────────────────────────────────────────────────────────────

    """
    echo "${greeting} from ${meta.id} ${args}" > ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """

    stub:
    // The stub: block runs when you use nextflow run -stub or nf-test with stubs.
    // It must create the same output files as the real script: block,
    // but without actually running the tool. Use 'touch' to create empty files.
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
