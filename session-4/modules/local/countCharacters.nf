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
