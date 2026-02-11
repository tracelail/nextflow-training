process ANALYZE_GREETING {
    publishDir "${params.outdir}/analysis", mode: 'copy'

    input:
    path greeting_file

    output:
    path "analysis_${greeting_file}"

    // no path needed for the analyze.sh even though it is located in bin/
    script:
    """
    analyze.sh ${greeting_file} analysis_${greeting_file}
    """
}
