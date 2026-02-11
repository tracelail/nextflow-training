// exercise_03.nf
// Demonstrates using helper scripts from bin/ directory

params.outdir = 'results_binscript'
params.names = ['Alice', 'Bob', 'Charlie']

include { SAY_HELLO } from './modules/local/sayHello'
include { ANALYZE_GREETING } from './modules/local/analyze'

workflow {
    names_ch = channel.fromList(params.names)

    SAY_HELLO(names_ch)
    ANALYZE_GREETING(SAY_HELLO.out)
}
