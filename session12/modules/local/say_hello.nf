/*
 * modules/local/say_hello.nf
 *
 * SAY_HELLO: writes a greeting to a file.
 *
 * NOTE FOR LEARNERS:
 *   The output here uses `val` as a stand-in so we can easily read
 *   the result back in nf-test assertions without a container.
 *   In a real pipeline this would be `path("${meta.id}_greeting.txt")`
 *   written from inside the script block. We use `val` here so the
 *   exercise stays runnable without Docker and the output value is
 *   directly accessible on `process.out`.
 */

process SAY_HELLO {

    tag "${meta.id}"

    input:
    tuple val(meta), val(greeting)

    output:
    tuple val(meta), val("${meta.id}: ${greeting}"), emit: result // have to change the val for a snapshot to change

    script:
    """
    echo "${meta.id}: ${greeting}"
    """
}
