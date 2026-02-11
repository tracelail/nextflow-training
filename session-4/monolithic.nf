// monolithic.nf
// Starting point: All processes in one file (will be refactored into modules)

params.outdir = 'results'
params.names = ['Alice', 'Bob', 'Charlie']

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

process CONVERT_TO_UPPER {
    publishDir "${params.outdir}/upper", mode: 'copy'

    input:
    path greeting_file

    output:
    path "upper_${greeting_file}"

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${greeting_file} > upper_${greeting_file}
    """
}

process COUNT_CHARACTERS {
    publishDir "${params.outdir}/stats", mode: 'copy'

    input:
    path greeting_file

    output:
    path "stats_${greeting_file}"

    script:
    """
    wc -m ${greeting_file} > stats_${greeting_file}
    """
}

workflow {
    // Create input channel
    names_ch = channel.fromList(params.names)

    // Chain the processes
    SAY_HELLO(names_ch)
    CONVERT_TO_UPPER(SAY_HELLO.out)
    COUNT_CHARACTERS(CONVERT_TO_UPPER.out)
}
