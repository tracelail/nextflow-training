/*
 * modules/local/convert_upper.nf
 *
 * CONVERT_UPPER: uppercases the greeting string.
 *
 * NOTE FOR LEARNERS:
 *   Same val-for-path trade-off as SAY_HELLO. In a real pipeline the
 *   uppercase result would be written to a file and emitted with `path`.
 *   Here we keep it as `val` so the output is easy to inspect directly
 *   in nf-test `then {}` blocks without any file I/O helpers.
 */

process CONVERT_UPPER {

    tag "${meta.id}"

    input:
    // tuple val(meta), val("${meta.id}: ${greeting}"), emit: result
    tuple val(meta), val(text)



    output:
    tuple val(meta), val(uppercased), emit: uppercased

    // script:
    // """
    // echo "${text.toUpperCase()}"
    // """
    // need exec block, not script for val preservation. Other option would be to write to a file
    exec:
    uppercased = text.toUpperCase()
}
