// ============================================================
// Session 10 — Bonus: transpose
// ============================================================
// Goal: See how transpose is the inverse of groupTuple.
//
// groupTuple: [key, a], [key, b]  →  [key, [a, b]]
// transpose:  [key, [a, b]]       →  [key, a], [key, b]
//
// transpose is useful when you receive pre-grouped data
// (e.g., from a config file or external tool) and need to
// expand it back into individual tuples for parallel processing.
// ============================================================

workflow {

    // ── Basic transpose ──────────────────────────────────────────────
    // Imagine these came from a database or config listing per-sample VCFs
    ch_grouped = channel.of(
        ['sampleA', ['chr1.vcf', 'chr2.vcf', 'chr3.vcf']],
        ['sampleB', ['chr1.vcf', 'chr2.vcf']]
    )

    ch_grouped
        .transpose()
        .view { sample, vcf -> "TRANSPOSED: ${sample} → ${vcf}" }
    // Output:
    //   TRANSPOSED: sampleA → chr1.vcf
    //   TRANSPOSED: sampleA → chr2.vcf
    //   TRANSPOSED: sampleA → chr3.vcf
    //   TRANSPOSED: sampleB → chr1.vcf
    //   TRANSPOSED: sampleB → chr2.vcf


    // ── Round-trip: groupTuple then transpose ─────────────────────────
    // Start with individual items, group them, then flatten again.
    ch_items = channel.of(
        ['sampleA', 'chr1.vcf'],
        ['sampleA', 'chr2.vcf'],
        ['sampleA', 'chr3.vcf'],
        ['sampleB', 'chr1.vcf'],
        ['sampleB', 'chr2.vcf']
    )

    ch_items
        .groupTuple()
        .tap { ch_after_group ->
            ch_after_group.view { sample, vcfs ->
                "AFTER groupTuple: ${sample} → ${vcfs}"
            }
        }
        .transpose()
        .view { sample, vcf ->
            "AFTER transpose: ${sample} → ${vcf}"
        }
    // After groupTuple: sampleA → [chr1.vcf, chr2.vcf, chr3.vcf]
    // After transpose:  sampleA → chr1.vcf  (×3, then sampleB ×2)


    // ── transpose with remainder: true ───────────────────────────────
    // When lists have different lengths, remainder: true fills gaps with null
    // instead of dropping unmatched positions.
    ch_uneven = channel.of(
        ['sampleA', ['chr1.vcf', 'chr2.vcf', 'chr3.vcf'], ['annot1', 'annot2', 'annot3']],
        ['sampleB', ['chr1.vcf', 'chr2.vcf'],             ['annot1']]  // second list shorter
    )

    ch_uneven
        .transpose(remainder: true)
        .view { sample, vcf, annot ->
            "UNEVEN: ${sample}  vcf=${vcf}  annot=${annot}"
        }
    // sampleB row 2: vcf=chr2.vcf  annot=null  (null fills the gap)
}
