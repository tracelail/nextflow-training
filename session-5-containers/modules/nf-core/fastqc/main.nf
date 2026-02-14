process FASTQC {
    tag "$meta.id"
    label 'process_medium'
    
    // Modern nf-core pattern: container resolution happens automatically
    // In real nf-core, this is managed by the infrastructure
    container 'biocontainers/fastqc:0.11.9--0'
    
    input:
    tuple val(meta), path(reads)
    
    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastqc \\
        $args \\
        --threads $task.cpus \\
        $reads
    """
    
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_fastqc.html
    touch ${prefix}_fastqc.zip
    """
}
