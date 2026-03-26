// modules/local/summarise.nf
//
// ── VIOLATION: the helper closure below uses a for loop ─────
// The script block itself is fine. The Groovy helper function
// `buildSummary` uses a for loop over a list.
// Fix: replace with .collect { } or .each { }

process SUMMARISE {
    tag "$meta.id"
    label 'process_low'

    input:
    val meta

    output:
    path "${meta.id}_summary.txt", emit: summary

    script:
    // ── VIOLATION: for loop inside script block ────────────
    // In strict syntax, for loops are banned everywhere in a
    // Nextflow script — including inside script: blocks' Groovy
    // code (the code before the triple-quoted shell heredoc).
    // Fix: .collect { } functional style
    def fields = ['id', 'strandedness']
    def lines = fields.collect { field -> "${field} : ${meta[field] ?: 'N/A'}" }
    def summary_text = lines.join('\n')
    """
    cat > ${meta.id}_summary.txt << 'EOF'
    ${summary_text}
    EOF
    """
}
