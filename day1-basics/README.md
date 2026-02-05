# Day 1: Nextflow Basics

Basic Nextflow concepts with modern syntax (2026 conventions).

## Files

- `hello.nf` - Basic println
- `process-basics.nf` - Understanding processes
- `process-input.nf` - Process with input
- `channels-basic.nf` - Parallel processing with channels
- `file-process.nf` - Working with files
- `file-process-multi.nf` - Multiple files with named outputs

## Running Examples
```bash
nextflow run hello.nf
nextflow run process-basics.nf
# ... etc
```

## Key Concepts Learned

- Processes are like functions that encapsulate tasks
- Channels enable parallel execution (like parallel for-loops)
- `stdout` captures terminal output as a channel
- Named outputs with `emit:` make code more readable
- Wildcards in `path` outputs capture dynamically created files
