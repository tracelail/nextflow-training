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
