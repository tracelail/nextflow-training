#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process TINY_TASK {
    label 'process_low'
    
    output:
    path "tiny.txt"
    
    script:
    """
    echo "Tiny: ${task.cpus} CPUs, ${task.memory}" > tiny.txt
    """
}

process MEDIUM_TASK {
    label 'process_medium'
    
    output:
    path "medium.txt"
    
    script:
    """
    echo "Medium: ${task.cpus} CPUs, ${task.memory}" > medium.txt
    """
}

process HUGE_TASK {
    label 'process_high'
    
    output:
    path "huge.txt"
    
    script:
    """
    echo "Huge: ${task.cpus} CPUs, ${task.memory}" > huge.txt
    """
}

process CUSTOM_TASK {
    // This process has no label, so only gets default settings
    
    output:
    path "custom.txt"
    
    script:
    """
    echo "Custom: ${task.cpus} CPUs, ${task.memory}" > custom.txt
    """
}

workflow {
    TINY_TASK()
    MEDIUM_TASK()
    HUGE_TASK()
    CUSTOM_TASK()
    
    TINY_TASK.out.view { file -> "Tiny: ${file.text.trim()}" }
    MEDIUM_TASK.out.view { file -> "Medium: ${file.text.trim()}" }
    HUGE_TASK.out.view { file -> "Huge: ${file.text.trim()}" }
    CUSTOM_TASK.out.view { file -> "Custom: ${file.text.trim()}" }
}
