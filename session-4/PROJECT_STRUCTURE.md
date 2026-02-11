# Session 4 - Project Structure

This document explains the organization of the Session 4 materials.

## Directory Tree

```
day-4/
├── README.md                    # Main learning guide
├── EXPECTED_OUTPUTS.md          # What you should see when running exercises
├── TESTING_GUIDE.md             # Step-by-step instructions
├── PROJECT_STRUCTURE.md         # This file
├── setup_session4.sh            # Setup verification script
│
├── monolithic.nf                # Starting point: all processes in one file
├── main.nf                      # Refactored: modular version
├── exercise_02.nf               # Process aliasing demonstration
├── exercise_03.nf               # bin/ directory demonstration
│
├── modules/                     # Module directory
│   └── local/                   # Local (custom) modules
│       ├── sayHello.nf          # SAY_HELLO process module
│       ├── convertToUpper.nf    # CONVERT_TO_UPPER process module
│       ├── countCharacters.nf   # COUNT_CHARACTERS process module
│       └── analyze.nf           # ANALYZE_GREETING process module
│
└── bin/                         # Helper scripts (auto-added to PATH)
    └── analyze.sh               # Custom analysis tool

After running exercises:
├── results/                     # From main.nf
│   ├── greetings/
│   ├── upper/
│   └── stats/
├── results_aliasing/            # From exercise_02.nf
│   └── greetings/
├── results_binscript/           # From exercise_03.nf
│   ├── greetings/
│   └── analysis/
└── work/                        # Nextflow work directories
    └── [hash]/[hash]/           # Task execution directories
```

## File Purposes

### Documentation Files

**README.md**
- Learning objectives for Session 4
- Conceptual explanations of modules, includes, bin/ directory
- Complete hands-on exercises with code examples
- Debugging tips
- Key takeaways

**EXPECTED_OUTPUTS.md**
- Detailed description of expected console output
- Expected directory structures
- Sample file contents
- Verification steps

**TESTING_GUIDE.md**
- Step-by-step walkthrough of all exercises
- Commands to run
- What to observe
- Troubleshooting section
- Completion checklist

**PROJECT_STRUCTURE.md** (this file)
- Overview of file organization
- Purpose of each file
- How files relate to each other

### Executable Files

**setup_session4.sh**
- Verifies all required files are present
- Checks directory structure
- Makes scripts executable
- Provides quick-start instructions

**bin/analyze.sh**
- Helper script for greeting analysis
- Demonstrates automatic PATH inclusion
- Used by ANALYZE_GREETING process

### Nextflow Scripts

**monolithic.nf**
- **Purpose:** Show the "before" state - all in one file
- **Processes:** SAY_HELLO, CONVERT_TO_UPPER, COUNT_CHARACTERS
- **Output:** results/ directory
- **Learning point:** This works but isn't reusable

**main.nf**
- **Purpose:** Show the "after" state - modular organization
- **Imports:** All three processes from separate modules
- **Output:** results/ directory (identical to monolithic)
- **Learning point:** Modularization doesn't change functionality

**exercise_02.nf**
- **Purpose:** Demonstrate process aliasing
- **Imports:** SAY_HELLO twice with different aliases
- **Output:** results_aliasing/ directory
- **Learning point:** Same module, independent instances

**exercise_03.nf**
- **Purpose:** Demonstrate bin/ directory usage
- **Imports:** SAY_HELLO and ANALYZE_GREETING
- **Output:** results_binscript/ directory
- **Learning point:** Scripts in bin/ are automatically available

### Module Files

**modules/local/sayHello.nf**
- **Contains:** SAY_HELLO process
- **Function:** Creates greeting files
- **Used by:** main.nf, exercise_02.nf, exercise_03.nf

**modules/local/convertToUpper.nf**
- **Contains:** CONVERT_TO_UPPER process
- **Function:** Converts greetings to uppercase
- **Used by:** main.nf

**modules/local/countCharacters.nf**
- **Contains:** COUNT_CHARACTERS process
- **Function:** Counts characters in files
- **Used by:** main.nf

**modules/local/analyze.nf**
- **Contains:** ANALYZE_GREETING process
- **Function:** Analyzes greeting files using bin/analyze.sh
- **Used by:** exercise_03.nf

## Workflow Dependencies

### main.nf workflow
```
channel.of(params.names)
    ↓
SAY_HELLO (from modules/local/sayHello.nf)
    ↓
CONVERT_TO_UPPER (from modules/local/convertToUpper.nf)
    ↓
COUNT_CHARACTERS (from modules/local/countCharacters.nf)
```

### exercise_02.nf workflow
```
channel.of(params.names)
    ↓
    ├─→ SAY_HELLO_FORMAL (alias from modules/local/sayHello.nf)
    └─→ SAY_HELLO_CASUAL (alias from modules/local/sayHello.nf)
```

### exercise_03.nf workflow
```
channel.of(params.names)
    ↓
SAY_HELLO (from modules/local/sayHello.nf)
    ↓
ANALYZE_GREETING (from modules/local/analyze.nf)
    ↓
[calls bin/analyze.sh automatically]
```

## Module Relationships

```
modules/local/
    │
    ├─ sayHello.nf ────────┬─→ Used by main.nf
    │                      ├─→ Used by exercise_02.nf (as FORMAL)
    │                      ├─→ Used by exercise_02.nf (as CASUAL)
    │                      └─→ Used by exercise_03.nf
    │
    ├─ convertToUpper.nf ──→ Used by main.nf
    │
    ├─ countCharacters.nf ─→ Used by main.nf
    │
    └─ analyze.nf ─────────→ Used by exercise_03.nf
                             └─→ Calls bin/analyze.sh
```

## Import Patterns Used

### Single process import
```nextflow
include { SAY_HELLO } from './modules/local/sayHello'
```

### Multiple imports from different files
```nextflow
include { SAY_HELLO } from './modules/local/sayHello'
include { CONVERT_TO_UPPER } from './modules/local/convertToUpper'
```

### Process aliasing
```nextflow
include { SAY_HELLO as SAY_HELLO_FORMAL } from './modules/local/sayHello'
include { SAY_HELLO as SAY_HELLO_CASUAL } from './modules/local/sayHello'
```

## bin/ Directory Pattern

**Automatic PATH inclusion:**
```
Nextflow automatically adds ${projectDir}/bin to PATH
    ↓
Any executable in bin/ is available to all processes
    ↓
No need to specify full paths or copy scripts
```

**Usage in process:**
```nextflow
script:
"""
analyze.sh input.txt output.txt
"""
```

**NOT needed:**
```nextflow
script:
"""
${projectDir}/bin/analyze.sh input.txt output.txt  # Too verbose
./bin/analyze.sh input.txt output.txt              # Wrong path
"""
```

## Key Design Patterns

### 1. One Process Per Module (Current Approach)
```
modules/local/sayHello.nf      → SAY_HELLO only
modules/local/convertToUpper.nf → CONVERT_TO_UPPER only
```
**Pros:** Clear, easy to find, simple imports
**Cons:** Many small files

### 2. Related Processes Per Module (Alternative)
```
modules/local/text_processing.nf → CONVERT_TO_UPPER, COUNT_CHARACTERS
```
**Pros:** Fewer files, grouped functionality
**Cons:** More complex imports, harder to reuse individual processes

**Best practice:** For Session 4, we use one-process-per-module for clarity. In real pipelines, group related processes.

## Future Sessions Preview

**Session 5 (Containers)** will add to these modules:
```nextflow
process SAY_HELLO {
    container 'ubuntu:22.04'  // ← Will add this
    
    // ... rest of process
}
```

**Session 6 (Configuration)** will configure these modules:
```nextflow
// nextflow.config
process {
    withName: 'SAY_HELLO_FORMAL' {
        ext.args = '--formal'
    }
}
```

**Session 16 (Creating nf-core modules)** will convert these to nf-core format:
```
modules/nf-core/sayhello/
    ├── main.nf
    ├── meta.yml
    ├── environment.yml
    └── tests/
```

## Recommended Study Order

1. **Read README.md** - Understand the concepts
2. **Run setup_session4.sh** - Verify everything is ready
3. **Follow TESTING_GUIDE.md** - Work through exercises step-by-step
4. **Refer to EXPECTED_OUTPUTS.md** - Verify your results
5. **Review this file** - Understand the overall structure

## Tips for Working with This Structure

### When modifying modules:
1. Edit the module file in `modules/local/`
2. Run with `-resume` to test just that module
3. Changes propagate to all workflows that import it

### When debugging:
1. Check console output for process names
2. Find work directory from console
3. Examine `.command.sh`, `.command.err`, `.exitcode`
4. For bin/ scripts, check they were copied to work directory

### When organizing your own projects:
1. Start with a monolithic script (easier to develop)
2. Refactor into modules once processes stabilize
3. Keep related processes together
4. Use bin/ for any custom scripts
5. Document your module organization

## Summary

This session's materials demonstrate three key organizational patterns:
1. **Module extraction** - Breaking monolithic code into reusable pieces
2. **Process aliasing** - Running the same code with different configurations
3. **Helper scripts** - Using bin/ for supporting tools

All patterns work together to create maintainable, reusable Nextflow pipelines!
