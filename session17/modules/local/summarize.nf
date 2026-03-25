process SUMMARIZE {
    input:
    path count_files
    val suffix

    output:
    path "pipeline_summary_${suffix}.txt", emit: summary

    publishDir params.outdir, mode: 'copy'

    script:
    """
    echo "=== Pipeline Summary ===" > pipeline_summary_${suffix}.txt
    echo "Generated: \$(date)" >> pipeline_summary_${suffix}.txt
    echo "Suffix: ${suffix}" >> pipeline_summary_${suffix}.txt
    echo "" >> pipeline_summary_${suffix}.txt

    for f in ${count_files}; do
        echo "--- \$f ---" >> pipeline_summary_${suffix}.txt
        cat \$f >> pipeline_summary_${suffix}.txt
        echo "" >> pipeline_summary_${suffix}.txt
    done

    cat pipeline_summary_${suffix}.txt
    """

    stub:
    """
    echo "=== Pipeline Summary ===" > pipeline_summary_${suffix}.txt
    echo "STUB MODE" >> pipeline_summary_${suffix}.txt
    """
}
