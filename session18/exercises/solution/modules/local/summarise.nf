// modules/local/summarise.nf  (SOLUTION — strict-syntax compliant)
//
// Changes from starter version:
//   ✓ for (field in fields) → .collect { field -> ... }
//     The .join() call then produces the same newline-joined string.

process SUMMARISE {
    tag "$meta.id"
    label 'process_low'

    input:
    val meta

    output:
    path "${meta.id}_summary.txt", emit: summary

    script:
    // ✓ No for loop — .collect { field -> ... } instead
    def fields       = ['id', 'strandedness']
    def summary_text = fields.collect { field -> "${field}: ${meta[field] ?: 'N/A'}" }.join('\n')
    """
    cat > ${meta.id}_summary.txt << 'EOF'
    ${summary_text}
    EOF
    """

    stub:
    """
    touch ${meta.id}_summary.txt
    """
}
