process WORD_COUNT {
    tag "$meta.id"

    input:
    tuple val(meta), path(data_file)
    val min_word_length

    output:
    tuple val(meta), path("${meta.id}.counts.txt"), emit: counts

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    echo "Sample: ${meta.id}" > ${prefix}.counts.txt
    echo "Condition: ${meta.condition}" >> ${prefix}.counts.txt
    echo "Replicate: ${meta.replicate}" >> ${prefix}.counts.txt
    echo "---" >> ${prefix}.counts.txt

    # Count total words
    total=\$(wc -w < ${data_file})
    echo "Total words: \$total" >> ${prefix}.counts.txt

    # Count words meeting minimum length
    long_words=\$(tr -s ' ' '\\n' < ${data_file} | awk 'length >= ${min_word_length}' | wc -l)
    echo "Words >= ${min_word_length} chars: \$long_words" >> ${prefix}.counts.txt

    cat ${prefix}.counts.txt
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    echo "Sample: ${meta.id}" > ${prefix}.counts.txt
    echo "Condition: ${meta.condition}" >> ${prefix}.counts.txt
    echo "Replicate: ${meta.replicate}" >> ${prefix}.counts.txt
    echo "---" >> ${prefix}.counts.txt
    echo "Total words: 42" >> ${prefix}.counts.txt
    echo "Words >= ${min_word_length} chars: 28" >> ${prefix}.counts.txt
    """
}
