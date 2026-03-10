/*
 * modules/local/collect_results.nf
 *
 * COLLECT_RESULTS: receives all uppercased greetings as a single list
 * and emits a summary count.
 *
 * NOTE FOR LEARNERS:
 *   The `collect()` operator upstream converts the queue channel into a
 *   value channel (a list). This process therefore runs exactly once,
 *   receiving every greeting together. That is the "gather" half of the
 *   scatter-gather pattern you practised in Session 10.
 *
 *   Again, `val` is used for the output to avoid needing file I/O in
 *   this training exercise. A production version would write a summary
 *   report file and emit it with `path`.
 */

process COLLECT_RESULTS {

    input:
    val all_results

    output:
    val summary, emit: summary

    exec:
    summary = "Processed ${all_results.size()} greetings: ${all_results.collect { item -> item[1] }.join(' | ')}"
}
