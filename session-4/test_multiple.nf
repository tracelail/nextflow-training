include { SAY_HELLO } from './modules/local/sayHello'
include { CONVERT_TO_UPPER } from './modules/local/convertToUpper'


workflow {
    channel.of('Test').set { ch }
    SAY_HELLO(ch)
}