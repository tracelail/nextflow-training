// solutions/03_scatter_gather_solution.nf
// Session 9 — Exercise 3 SOLUTION (with groupTuple size: 4)

process CALL_VARIANTS {
    tag "${meta.id}:${interval}"

    input:
    tuple val(meta), val(interval)

    output:
    tuple val(meta), val("${meta.id}_${interval}.vcf")

    script:
    """
    echo "Calling variants for ${meta.id} on ${interval}"
    """
}

process MERGE_VCFS {
    tag "${meta.id}"

    publishDir 'results/merged', mode: 'copy'

    input:
    tuple val(meta), val(vcf_list)

    output:
    tuple val(meta), path("${meta.id}_merged.txt")

    script:
    """
    echo "Sample: ${meta.id}" > ${meta.id}_merged.txt
    echo "Merged VCFs: ${vcf_list.join(', ')}" >> ${meta.id}_merged.txt
    """
}

workflow {

    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .filter { row -> row.type == 'tumor' }
        .map { row -> [ [id: row.sample_id, type: row.type], row.fastq_1 ] }

    ch_intervals = channel.fromPath( 'data/intervals.csv' )
        .splitCsv( header: true )
        .map { row -> row.interval }

    // SCATTER
    ch_scattered = ch_samples.combine( ch_intervals )
    ch_scattered.view { meta, fq, interval -> "Scattered: ${meta.id} x ${interval}" }

    CALL_VARIANTS( ch_scattered.map { meta, fq, interval -> [meta, interval] } )

    // GATHER — size: 4 because we have 4 intervals
    ch_gathered = CALL_VARIANTS.out
        .groupTuple( size: 4 )

    ch_gathered.view { meta, vcfs -> "Gathered ${meta.id}: ${vcfs.size()} VCFs" }

    MERGE_VCFS( ch_gathered )

    MERGE_VCFS.out.view { meta, merged -> "Final: ${meta.id} -> ${merged}" }

}
