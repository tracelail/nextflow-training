// main.nf
// Modular version: Processes imported from separate module files

params.outdir = 'results'
params.names = ['Alice', 'Bob', 'Charlie']

// Import the processes from modules
include { SAY_HELLO } from './modules/local/sayHello'   // use relative path for from
include { CONVERT_TO_UPPER } from './modules/local/convertToUpper'
include { COUNT_CHARACTERS } from './modules/local/countCharacters'

workflow {
    // Create input channel
    names_ch = channel.fromList(params.names)

    // Chain the processes
    SAY_HELLO(names_ch)
    CONVERT_TO_UPPER(SAY_HELLO.out)
    COUNT_CHARACTERS(CONVERT_TO_UPPER.out)
}
