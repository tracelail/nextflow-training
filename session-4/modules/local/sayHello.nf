process SAY_HELLO {
    publishDir "${params.outdir}/greetings", mode: 'copy'

    input:
    val name

    output:
    path "greeting_${name}.txt"

    script:
    """
    echo "Hello, ${name}! Welcome to Nextflow." > greeting_${name}.txt
    """
}
