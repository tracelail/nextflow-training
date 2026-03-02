// ============================================================
// Session 10 — Exercise 3: Full Scatter-Gather Pipeline
// ============================================================
// Goal: Implement a realistic scatter-gather pattern:
//
//   samplesheet → ALIGN (one task per sample)
//              → combine with intervals (scatter: N×M tasks)
//              → GENOTYPE_INTERVAL (parallel per combination)
//              → groupTuple (gather: collect interval results)
//              → MERGE_VCFS (one merge per sample)
//
// Key concepts:
//   - combine creates the Cartesian product (scatter)
//   - groupKey tells groupTuple when a group is complete
//   - groupKey.target unwraps back to the plain meta map
//
// 2026 syntax rules followed:
//   ✓ lowercase channel factories
//   ✓ explicit closure parameters
//   ✓ tuple/val/path qualifiers
// ============================================================

// ── Processes ─────────────────────────────────────────────────────────────

process ALIGN {
    // tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.bam")

    script:
    """
    # Simulate alignment — in a real pipeline this would be bwa mem, STAR, etc.
    echo "Aligned reads for ${meta.id} (${meta.type})" > ${meta.id}.bam
    echo "Source reads: ${reads}"                      >> ${meta.id}.bam
    """
}

process GENOTYPE_INTERVAL {
    // This process runs ONCE PER SAMPLE×INTERVAL COMBINATION
    // tag "${meta.id}"

    input:
    tuple val(meta), path(bam), val(interval)

    output:
    // groupKey wraps meta with the expected group size (num_intervals).
    // groupTuple will emit this sample's group as soon as num_intervals
    // results arrive — without waiting for the whole pipeline to finish.
    tuple val(meta), path("*.vcf")

    // script:
    // """
    // echo "Genotyping ${meta.id} on interval ${interval}" > ${meta.id}.${interval}.vcf
    // echo "BAM: ${bam}"                                  >> ${meta.id}.${interval}.vcf
    // echo "Interval: ${interval}"                        >> ${meta.id}.${interval}.vcf
    // """

    script:
    '''
    echo "Genotyping !{meta.id} on interval !{interval}" > !{meta.id}.!{interval}.vcf
    echo "BAM: !{bam}"                                   >> !{meta.id}.!{interval}.vcf
    echo "Interval: !{interval}"                         >> !{meta.id}.!{interval}.vcf
    '''
}

process MERGE_VCFS {
    // This process runs ONCE PER SAMPLE with all interval VCFs collected
    // tag "${meta.id}"
    publishDir "results/vcfs", mode: 'copy'

    input:
    // After groupTuple the VCF files arrive as a list.
    // Nextflow stages them as input/chunk_0.vcf, input/chunk_1.vcf etc.
    tuple val(meta), path("input/chunk_?.vcf")

    output:
    tuple val(meta), path("*.merged.vcf")

    script:
    """
    echo "=== Merged VCF for ${meta.id} (${meta.type}) ===" > ${meta.id}.merged.vcf
    echo ""                                                  >> ${meta.id}.merged.vcf
    cat input/chunk_*.vcf                                    >> ${meta.id}.merged.vcf
    """
}

// ── Workflow ───────────────────────────────────────────────────────────────

workflow {

    // Number of intervals we will scatter across.
    // Hardcoded here so groupKey can reference it; in a real pipeline
    // you would derive this from the interval BED file count.
    def NUM_INTERVALS = 3

    // ── Inputs ───────────────────────────────────────────────────────
    ch_samples = channel
        .fromPath("${projectDir}/data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            // Add num_intervals so GENOTYPE_INTERVAL can use it in groupKey
            def meta  = [id: row.sample_id, type: row.type, num_intervals: NUM_INTERVALS]
            def reads = file("${projectDir}/data/${row.fastq}")
            [meta, reads]
        }

    // Intervals to scatter across.
    // In a real variant-calling pipeline these would be BED files or
    // chromosome names split from a sequence dictionary.
    ch_intervals = channel.of('chr1', 'chr2', 'chr3')

    ch_samples.view { meta, _reads ->
        "INPUT: ${meta.id} (${meta.type})"
    }


    // ── Step 1: Align each sample (one task per sample) ──────────────
    ALIGN(ch_samples)


    // ── Step 2: Scatter — combine each BAM with every interval ────────
    //
    // combine produces the Cartesian product:
    //   [meta, bam] × [interval] → [meta, bam, interval]
    //
    // 4 samples × 3 intervals = 12 tasks run in parallel
    //
    ch_scattered = ALIGN.out.combine(ch_intervals)

    ch_scattered.view { meta, _bam, interval ->
        "SCATTERED: ${meta.id} × ${interval}  (${meta.type})"
    }


    // ── Step 3: Genotype each combination ─────────────────────────────
    GENOTYPE_INTERVAL(ch_scattered)


    // ── Step 4: Gather — groupTuple collects interval results ─────────
    //
    // groupKey (set in GENOTYPE_INTERVAL output) told Nextflow that each
    // sample has exactly NUM_INTERVALS results. groupTuple emits a group
    // as soon as it is complete, enabling streaming rather than waiting.
    //
    // After groupTuple the tuple is: [groupKey_object, [vcf1, vcf2, vcf3]]
    // We must unwrap groupKey with .target to get the plain meta map back.
    //
    ch_gathered = GENOTYPE_INTERVAL.out
        .map { meta, vcf -> [groupKey(meta, meta.num_intervals), vcf] }
        .groupTuple()
        .map { key, vcfs ->
            // key is a GroupKey object — .target gives back the plain map
            [key.target, vcfs]
        }

    ch_gathered.view { meta, vcfs ->
        "GATHERED: ${meta.id} — ${vcfs.size()} VCF chunks ready to merge"
    }


    // ── Step 5: Merge all interval VCFs per sample ────────────────────
    MERGE_VCFS(ch_gathered)

    MERGE_VCFS.out.view { meta, merged ->
        "FINAL OUTPUT: ${meta.id} (${meta.type}) → ${merged.name}"
    }
}
