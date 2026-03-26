// modules/local/multiqc.nf
//
// This module is already strict-syntax compliant.
// It uses lowercase channel (via topic), explicit closure params,
// and a script: block. Notice what "clean" looks like — compare
// against fastqc.nf and trim_reads.nf which you will need to fix.

process MULTIQC {
    label 'process_low'

    conda 'bioconda::multiqc=1.25.1'
    container 'quay.io/biocontainers/multiqc:1.25.1--pyhdfd78af_0'

    input:
    path fastqc_zips
    path trim_logs

    output:
    path "*multiqc_report.html", emit: report
    path "*_data",               emit: data
    path "*_plots",              emit: plots, optional: true

    script:
    def title_arg = params.multiqc_title ? "--title '${params.multiqc_title}'" : ''
    """
    multiqc \\
        --force \\
        ${title_arg} \\
        .
    """
}
