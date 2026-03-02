// ============================================================
// Session 10 — Exercise 2: join and groupTuple
// ============================================================
// Goal: Branch a samplesheet into tumor/normal streams,
//       process each independently, then rejoin results
//       by sample ID using join.
//
// 2026 syntax rules followed:
//   ✓ lowercase channel.fromPath / splitCsv
//   ✓ explicit closure parameters
//   ✓ processes use tuple/val/path (not set/file)
// ============================================================

// ── Processes ─────────────────────────────────────────────────────────────

process PROCESS_TUMOR {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_tumor.txt")

    script:
    """
    echo "Tumor analysis result for ${meta.id}" > ${meta.id}_tumor.txt
    echo "Reads file: ${reads}"                >> ${meta.id}_tumor.txt
    """
}

process PROCESS_NORMAL {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_normal.txt")

    script:
    """
    echo "Normal analysis result for ${meta.id}" > ${meta.id}_normal.txt
    echo "Reads file: ${reads}"                  >> ${meta.id}_normal.txt
    """
}

process COMBINE_PAIR {
    tag "${meta.id}"
    publishDir "results/pairs", mode: 'copy'

    input:
    // After join: [meta, tumor_file, normal_file]
    tuple val(meta), path(tumor_result), path(normal_result)

    output:
    tuple val(meta), path("${meta.id}_combined.txt")

    script:
    """
    echo "=== Combined report for ${meta.id} ===" > ${meta.id}_combined.txt
    echo ""                                       >> ${meta.id}_combined.txt
    echo "--- Tumor ---"                          >> ${meta.id}_combined.txt
    cat ${tumor_result}                           >> ${meta.id}_combined.txt
    echo ""                                       >> ${meta.id}_combined.txt
    echo "--- Normal ---"                         >> ${meta.id}_combined.txt
    cat ${normal_result}                          >> ${meta.id}_combined.txt
    """
}

// ── Workflow ───────────────────────────────────────────────────────────────

workflow {

    // ── Read samplesheet ───────────────────────────────────────────
    ch_samples = channel
        .fromPath("${projectDir}/data/samplesheet.csv")
        .splitCsv(header: true)
        .map { row ->
            def meta  = [id: row.sample_id, type: row.type]
            def reads = file("${projectDir}/data/${row.fastq}")
            [meta, reads]
        }

    ch_samples.view { meta, _reads -> "INPUT: ${meta.id} (${meta.type})" }


    // ── Split into tumor and normal ─────────────────────────────────
    ch_samples
        .branch { meta, _reads ->
            tumor:  meta.type == 'tumor'
            normal: meta.type == 'normal'
            other:  true
        }
        .set { ch_branched }


    // ── Process each stream independently ──────────────────────────
    PROCESS_TUMOR(ch_branched.tumor)
    PROCESS_NORMAL(ch_branched.normal)


    // ── join: pair tumor and normal results by sample ID ───────────
    //
    // join matches on the FIRST element of each tuple.
    // Our meta maps contain {id, type} — but tumor has type='tumor'
    // and normal has type='normal', so they are NOT equal as-is.
    //
    // Solution: strip to a common key [id only] before joining.
    //
    ch_tumor_keyed  = PROCESS_TUMOR.out
        .map { meta, file -> [ [id: meta.id], file ] }

    ch_normal_keyed = PROCESS_NORMAL.out
        .map { meta, file -> [ [id: meta.id], file ] }

    // Inner join — only samples present in BOTH channels are emitted
    ch_joined = ch_tumor_keyed.join(ch_normal_keyed)
    // Result shape: [ [id:'sampleA'], tumor_file, normal_file ]

    ch_joined.view { meta, t, n -> "JOINED: ${meta.id}  tumor=${t.name}  normal=${n.name}" }

    COMBINE_PAIR(ch_joined)

    COMBINE_PAIR.out.view { meta, combined ->
        "COMBINED OUTPUT: ${meta.id} → ${combined}"
    }


    // ── Outer join (remainder: true) ────────────────────────────────
    //
    // What if a sample has tumor data but no normal?
    // remainder: true keeps unmatched items, filling the missing side with null.
    //
    ch_orphan = channel.of( [[id: 'sampleX'], file("${projectDir}/data/extra.fastq")] )

    ch_tumor_keyed
        .mix(ch_orphan)                               // add an unmatched sample
        .join(ch_normal_keyed, remainder: true)       // outer join
        .view { meta, tumor, normal ->
            "OUTER JOIN: ${meta.id}  tumor=${tumor}  normal=${normal}"
        }
    // sampleX will appear with normal=null
}
