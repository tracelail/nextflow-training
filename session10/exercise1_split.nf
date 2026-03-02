// ============================================================
// Session 10 — Exercise 1: filter vs branch
// ============================================================
// Goal: Understand the two ways to split a channel into
//       multiple streams.
//
// 2026 syntax rules followed:
//   ✓ lowercase channel.of()
//   ✓ explicit closure parameters (no implicit 'it')
//   ✓ no top-level code outside workflow block
// ============================================================

workflow {

    // A channel of sample metadata maps
    ch_samples = channel.of(
        [id: 'sampleA', type: 'tumor',  depth: 50],
        [id: 'sampleB', type: 'normal', depth: 40],
        [id: 'sampleC', type: 'tumor',  depth: 35],
        [id: 'sampleD', type: 'normal', depth: 60],
        [id: 'sampleE', type: 'tumor',  depth: 20]
    )

    // ────────────────────────────────────────────────────────
    // APPROACH 1: filter
    //   - Keeps items that pass the boolean test
    //   - Silently drops everything else
    //   - Must call filter TWICE to get two separate streams
    //   - Each item is evaluated twice
    // ────────────────────────────────────────────────────────

    ch_tumor_filter  = ch_samples.filter { meta -> meta.type == 'tumor'  }
    ch_normal_filter = ch_samples.filter { meta -> meta.type == 'normal' }

    ch_tumor_filter .view { meta -> "TUMOR  (filter): ${meta.id}  depth=${meta.depth}" }
    ch_normal_filter.view { meta -> "NORMAL (filter): ${meta.id}  depth=${meta.depth}" }


    // ────────────────────────────────────────────────────────
    // APPROACH 2: branch
    //   - Routes each item to the FIRST matching sub-channel
    //   - Each item is evaluated exactly ONCE
    //   - Named outputs accessed via .tumor, .normal, etc.
    //   - 'other: true' is a catch-all — never omit it!
    // ────────────────────────────────────────────────────────

    ch_samples
        .branch { meta ->
            tumor:  meta.type == 'tumor'
            normal: meta.type == 'normal'
            other:  true    // catch-all: items matching nothing above land here
        }
        .set { ch_branched }

    ch_branched.tumor .view { meta -> "TUMOR  (branch): ${meta.id}  depth=${meta.depth}" }
    ch_branched.normal.view { meta -> "NORMAL (branch): ${meta.id}  depth=${meta.depth}" }
    ch_branched.other .view { meta -> "OTHER  (branch): ${meta.id}  — unexpected type!" }


    // ────────────────────────────────────────────────────────
    // DEEPER: branch with multiple conditions per stream
    //   - Conditions are evaluated IN ORDER; first match wins
    //   - You can also transform the emitted value per branch
    // ────────────────────────────────────────────────────────

    ch_samples
        .branch { meta ->
            high_tumor: meta.type == 'tumor'  && meta.depth >= 40
                return meta + [priority: 'high']   // transform the emitted item
            low_tumor:  meta.type == 'tumor'  && meta.depth <  40
                return meta + [priority: 'low']
            normal:     meta.type == 'normal'
            other:      true
        }
        .set { ch_detailed }

    ch_detailed.high_tumor.view { meta -> "HIGH TUMOR : ${meta.id}  priority=${meta.priority}" }
    ch_detailed.low_tumor .view { meta -> "LOW  TUMOR : ${meta.id}  priority=${meta.priority}" }
    ch_detailed.normal    .view { meta -> "NORMAL     : ${meta.id}" }


    // ────────────────────────────────────────────────────────
    // FILTER on a computed value
    //   - filter works with any Groovy expression
    //   - Useful for simple boolean subsetting
    // ────────────────────────────────────────────────────────

    ch_high_depth = ch_samples.filter { meta -> meta.depth >= 40 }
    ch_high_depth.view { meta -> "HIGH DEPTH (>= 40): ${meta.id}  depth=${meta.depth}" }
}
