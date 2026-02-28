// exercises/03_scatter_gather.nf
// Session 9 — Exercise 3: The Scatter-Gather Pattern
//
// Run: nextflow run exercises/03_scatter_gather.nf
//
// Pattern:
//   samples × intervals  →  combine (scatter)
//   CALL_VARIANTS        →  12 parallel tasks
//   groupTuple           →  gather by sample
//   MERGE_VCFS           →  3 final merged results

// ── Processes ────────────────────────────────────────────────────────────────

// Simulates per-interval variant calling (the SCATTER step)
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

// Simulates merging per-interval VCFs into one file (the GATHER step)
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


// ── Workflow ─────────────────────────────────────────────────────────────────

workflow {

    // 1. Load tumor samples from the samplesheet
    ch_samples = channel.fromPath( 'data/samplesheet.csv' )
        .splitCsv( header: true )
        .filter { row -> row.type == 'tumor' }
        .map { row -> [ [id: row.sample_id, type: row.type], row.fastq_1 ] }
        .view { meta, fastq1 -> "\nch_samples\n id: ${meta.id}, type: ${meta.type}, \nfastq: ${fastq1}" }

    // 2. Load genomic intervals
    ch_intervals = channel.fromPath( 'data/intervals.csv' )
        .splitCsv( header: true )
        .map { row -> row.interval }    // should just be the first column
        .view { interval -> "\nch_intervals\n interval: ${interval}"}

    // 3. SCATTER: combine produces every sample × interval combination
    //    3 samples × 4 intervals = 12 items
    ch_scattered = ch_samples.combine( ch_intervals )

    ch_scattered.view { meta, _fq, interval ->
        "Scattered: ${meta.id} x ${interval}"
    }

    // 4. Run variant calling on each of the 12 combinations in parallel
    CALL_VARIANTS( ch_scattered.map { meta, _fq, interval -> [meta, interval] } )

    // 5. GATHER: groupTuple groups all outputs sharing the same meta key
    //    Each meta map [id: 'SAMPLE_A', type: 'tumor'] becomes one group
    ch_gathered = CALL_VARIANTS.out
        .groupTuple( size:4 )

    ch_gathered.view { meta, vcfs ->
        "Gathered ${meta.id}: ${vcfs.size()} VCFs \n vcf files: ${vcfs}"
    }

    // 6. Merge all per-interval VCFs into one result per sample
    MERGE_VCFS( ch_gathered )

    MERGE_VCFS.out.view { meta, merged ->
        "Final: ${meta.id} -> ${merged}"
    }

    // ── TODO Step 5 ───────────────────────────────────────────────────────────
    // Change groupTuple() to groupTuple( size: 4 ) and re-run.
    // With size specified, groups emit as soon as they are full
    // rather than waiting for the entire channel to close.
    // This prevents pipeline hangs in large real-world pipelines.

}
