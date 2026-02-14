# Session 5 Summary

## What You Learned

### Core Concepts Mastered

1. **Container Fundamentals**
   - What containers are and why they ensure reproducibility
   - Difference between Docker and Singularity/Apptainer
   - When to use each runtime (local dev vs HPC)

2. **Nextflow Container Integration**
   - Using the `container` directive in processes
   - How Nextflow automatically mounts work directories
   - Container image resolution and pulling

3. **Configuration Patterns**
   - Profile-based runtime selection (`-profile docker` vs `-profile singularity`)
   - Docker and Singularity configuration scopes
   - Setting `runOptions` for permission management

4. **Modern nf-core Approach**
   - `environment.yml` for dependency specification
   - Seqera Containers and Wave for automatic builds
   - Module structure with separate concerns (logic, dependencies, docs)

### Hands-On Skills Developed

- ✅ Running containerized processes
- ✅ Configuring Docker and Singularity profiles
- ✅ Understanding container directives
- ✅ Working with Biocontainers registry
- ✅ Recognizing nf-core module patterns
- ✅ Debugging container-related issues

## Key Files You Created

### Workflows
- `01_basic_container.nf` - Single containerized process
- `02_multiprofile_container.nf` - Multi-tool, multi-profile pipeline

### Configuration
- `nextflow.config` - Basic Docker configuration
- `nextflow_multiprofile.config` - Advanced multi-profile setup

### Data
- `data/sample1.fastq` - Test FASTQ file
- `data/sample2.fastq` - Additional sample
- `data/sample3.fastq` - Third sample

### Module Example
- `modules/nf-core/fastqc/main.nf` - Process definition
- `modules/nf-core/fastqc/environment.yml` - Conda dependencies
- `modules/nf-core/fastqc/meta.yml` - Module metadata

## Important Syntax Patterns Learned

### Container Directive
```nextflow
process EXAMPLE {
    container 'biocontainers/tool:version'
    
    input:
    path(input_file)
    
    output:
    path('output_file')
    
    script:
    """
    tool ${input_file} > output_file
    """
}
```

### Docker Configuration
```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'  // Run as current user
}
```

### Profile Configuration
```groovy
profiles {
    docker {
        docker.enabled = true
    }
    
    singularity {
        singularity.enabled = true
        singularity.autoMounts = true
    }
}
```

### nf-core Module Pattern
```nextflow
process TOOL {
    tag "$meta.id"                    // Tag for logging
    label 'process_medium'            // Resource label
    container 'registry/image:tag'    // Container
    
    input:
    tuple val(meta), path(reads)      // Meta map pattern
    
    output:
    tuple val(meta), path("*.html"), emit: html
    
    script:
    def args = task.ext.args ?: ''    // Configurable args
    """
    tool $args $reads
    """
}
```

## Common Pitfalls Avoided

1. **Permission Issues**: Used `runOptions = '-u $(id -u):$(id -g)'` to run as current user
2. **Mount Problems**: Enabled `autoMounts = true` for Singularity
3. **Version Ambiguity**: Always specified exact container tags, never `:latest`
4. **Platform Mismatch**: Understood ARM64 vs AMD64 architecture differences
5. **Cache Invalidation**: Learned how containers interact with Nextflow's resume feature

## Real-World Applications

### Containers Solve These Problems

1. **"Works on my machine"** → Same container = same environment everywhere
2. **Dependency hell** → Tools isolated in containers, no conflicts
3. **Version drift** → Pin container versions for reproducibility
4. **Installation complexity** → Pull and run, no compilation needed
5. **Collaboration friction** → Share container tags, not installation docs

### When You'll Use This

- Running pipelines on different clusters (local, HPC, cloud)
- Ensuring your results are reproducible years later
- Collaborating with others who have different systems
- Contributing to nf-core (all modules must be containerized)
- Running legacy tools on modern systems

## Connection to Previous Sessions

### Built Upon
- **Session 1**: Basic process execution
- **Session 2**: Channel creation and data flow
- **Session 3**: Multi-process workflows
- **Session 4**: Modularization and code organization

### Extended With
- Container isolation for each process
- Profile-based configuration for different environments
- Modern dependency management with environment.yml

## Preparation for Session 6

Session 6 will build on containers by exploring:
- **Configuration hierarchy**: How settings override each other
- **Resource allocation**: CPU, memory, time limits
- **Selectors**: `withName`, `withLabel` for process-specific config
- **Executors**: Configuring SLURM, PBS, AWS Batch
- **Advanced profiles**: Combining multiple configuration dimensions

You now understand the "container" part of process configuration. Session 6 will cover the "resource" and "executor" parts.

## Testing Your Knowledge

Can you answer these questions?

1. What is the difference between Docker and Singularity? When would you use each?
2. Why is `-u $(id -u):$(id -g)` important in Docker runOptions?
3. How does Nextflow know where to find a container image?
4. What is the purpose of `environment.yml` in nf-core modules?
5. How do containers interact with Nextflow's `-resume` feature?
6. Why should you avoid using `:latest` container tags?
7. What happens if you specify a container that doesn't exist?
8. How would you test a container before using it in a workflow?

**Answers are throughout the README.md and EXPECTED_OUTPUTS.md!**

## Next Steps

1. **Review** the README.md and ensure you understand all concepts
2. **Experiment** with different container images from Biocontainers
3. **Explore** the nf-core modules repository for real examples
4. **Practice** switching between Docker and Singularity profiles
5. **Prepare** for Session 6 by thinking about resource allocation

## Additional Practice Ideas

1. Add a new tool (e.g., `trimmomatic`) to the workflow
2. Create your own custom Dockerfile
3. Build a module following nf-core conventions
4. Configure the workflow for a SLURM cluster
5. Implement error handling for missing containers

## Resources for Continued Learning

### Official Documentation
- Nextflow containers: https://www.nextflow.io/docs/latest/container.html
- Docker docs: https://docs.docker.com/
- Singularity docs: https://sylabs.io/docs/

### Container Registries
- Biocontainers: https://biocontainers.pro/
- Docker Hub: https://hub.docker.com/
- Quay.io: https://quay.io/

### nf-core Resources
- Modules: https://nf-co.re/modules
- Module guidelines: https://nf-co.re/docs/contributing/modules
- Seqera Containers: https://seqera.io/containers/

## Session Statistics

- **Concepts Covered**: 4 major topics
- **Files Created**: 10+ files
- **Exercises**: 3 progressive challenges
- **Commands Learned**: 15+ new patterns
- **Time Investment**: ~60 minutes
- **Lines of Code**: ~500 lines

---

**Congratulations on completing Session 5!** 🎉

You now understand how to leverage containers for reproducible, portable Nextflow pipelines. This is a critical skill for bioinformatics and data science workflows.

Ready for Session 6? Let's dive into advanced configuration and resource management!
