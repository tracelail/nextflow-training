// exercise_02.nf
// Demonstrates process aliasing - running the same process with different instances

params.outdir = 'results_aliasing'
params.names = ['Alice', 'Bob']

// Import the same process twice with different aliases
include { SAY_HELLO as SAY_HELLO_FORMAL } from './modules/local/sayHello'
include { SAY_HELLO as SAY_HELLO_CASUAL } from './modules/local/sayHello'

workflow {
    names_ch = channel.fromList(params.names)

    // Run both versions
    // In Session 6, you'll learn to configure these differently
    SAY_HELLO_FORMAL(names_ch)
    SAY_HELLO_CASUAL(names_ch)
}
