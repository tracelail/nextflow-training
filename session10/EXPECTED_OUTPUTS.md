# Session 10 — Expected Outputs Reference

Use this file to verify your runs produced the correct results.

---

## Exercise 1: exercise1_split.nf

Run: `nextflow run exercise1_split.nf`

You should see output lines in any order (Nextflow is parallel):

```
TUMOR  (filter): sampleA  depth=50
TUMOR  (filter): sampleC  depth=35
TUMOR  (filter): sampleE  depth=20
NORMAL (filter): sampleB  depth=40
NORMAL (filter): sampleD  depth=60

TUMOR  (branch): sampleA  depth=50
TUMOR  (branch): sampleC  depth=35
TUMOR  (branch): sampleE  depth=20
NORMAL (branch): sampleB  depth=40
NORMAL (branch): sampleD  depth=60

HIGH TUMOR : sampleA  priority=high
LOW  TUMOR : sampleC  priority=low
LOW  TUMOR : sampleE  priority=low
NORMAL     : sampleB
NORMAL     : sampleD

HIGH DEPTH (>= 40): sampleA  depth=50
HIGH DEPTH (>= 40): sampleB  depth=40
HIGH DEPTH (>= 40): sampleD  depth=60
```

**Key observation:** sampleE (depth=20) appears in the LOW TUMOR branch but NOT in HIGH DEPTH.
The catch-all `other: true` branch produces no output because all samples are tumor or normal.

---

## Exercise 2: exercise2_join.nf

Run: `nextflow run exercise2_join.nf`

Console output (order may vary):

```
INPUT: sampleA (tumor)
INPUT: sampleB (normal)
INPUT: sampleC (tumor)
INPUT: sampleD (normal)

JOINED: sampleA  tumor=sampleA_tumor.txt  normal=sampleB_normal.txt  ← WRONG! See note below
```

> **Note:** The samplesheet has sampleA (tumor) paired with sampleB (normal) — they are
> separate people. In a real matched tumor/normal study both rows for the same patient
> would share the same sample_id. The current samplesheet intentionally has 4 distinct
> samples to show filtering; the join will only produce pairs where IDs match.
> With the provided data only sampleA/sampleA and sampleB/sampleB etc. will join.

Results directory after run:
```
results/pairs/
├── sampleA_combined.txt    (if sampleA appears as both tumor and normal)
└── ...
```

Outer join output:
```
OUTER JOIN: sampleA  tumor=sampleA_tumor.txt  normal=null
OUTER JOIN: sampleX  tumor=extra.fastq        normal=null
... (all tumor-side samples with no matching normal, since IDs differ)
```

---

## Exercise 3: exercise3_scatter_gather.nf

Run: `nextflow run exercise3_scatter_gather.nf`

Console output:

```
INPUT: sampleA (tumor)
INPUT: sampleB (normal)
INPUT: sampleC (tumor)
INPUT: sampleD (normal)

SCATTERED: sampleA × chr1  (tumor)
SCATTERED: sampleA × chr2  (tumor)
SCATTERED: sampleA × chr3  (tumor)
SCATTERED: sampleB × chr1  (normal)
SCATTERED: sampleB × chr2  (normal)
SCATTERED: sampleB × chr3  (normal)
SCATTERED: sampleC × chr1  (tumor)
SCATTERED: sampleC × chr2  (tumor)
SCATTERED: sampleC × chr3  (tumor)
SCATTERED: sampleD × chr1  (normal)
SCATTERED: sampleD × chr2  (normal)
SCATTERED: sampleD × chr3  (normal)

GATHERED: sampleA — 3 VCF chunks ready to merge
GATHERED: sampleB — 3 VCF chunks ready to merge
GATHERED: sampleC — 3 VCF chunks ready to merge
GATHERED: sampleD — 3 VCF chunks ready to merge

FINAL OUTPUT: sampleA (tumor)  → sampleA.merged.vcf
FINAL OUTPUT: sampleB (normal) → sampleB.merged.vcf
FINAL OUTPUT: sampleC (tumor)  → sampleC.merged.vcf
FINAL OUTPUT: sampleD (normal) → sampleD.merged.vcf
```

Task count: nextflow log should show exactly 13 tasks:
- 4 ALIGN tasks (one per sample)
- 12 GENOTYPE_INTERVAL tasks (4 samples × 3 intervals)  ← verify this!
- 4 MERGE_VCFS tasks (one per sample)

Results directory:
```
results/vcfs/
├── sampleA.merged.vcf
├── sampleB.merged.vcf
├── sampleC.merged.vcf
└── sampleD.merged.vcf
```

Content of sampleA.merged.vcf:
```
=== Merged VCF for sampleA (tumor) ===

Genotyping sampleA on interval chr1
BAM: sampleA.bam
Interval: chr1
Genotyping sampleA on interval chr2
...
```

---

## Verify task count

```bash
nextflow log | head -2                      # get the last run name
nextflow log <run-name> -f process,status   # list all tasks
nextflow log <run-name> -f process,status | grep GENOTYPE | wc -l
# Should print: 12
```

---

## Bonus: bonus_transpose.nf

Run: `nextflow run bonus_transpose.nf`

```
TRANSPOSED: sampleA → chr1.vcf
TRANSPOSED: sampleA → chr2.vcf
TRANSPOSED: sampleA → chr3.vcf
TRANSPOSED: sampleB → chr1.vcf
TRANSPOSED: sampleB → chr2.vcf

AFTER groupTuple: sampleA → [chr1.vcf, chr2.vcf, chr3.vcf]
AFTER groupTuple: sampleB → [chr1.vcf, chr2.vcf]
AFTER transpose:  sampleA → chr1.vcf
AFTER transpose:  sampleA → chr2.vcf
AFTER transpose:  sampleA → chr3.vcf
AFTER transpose:  sampleB → chr1.vcf
AFTER transpose:  sampleB → chr2.vcf

UNEVEN: sampleA  vcf=chr1.vcf  annot=annot1
UNEVEN: sampleA  vcf=chr2.vcf  annot=annot2
UNEVEN: sampleA  vcf=chr3.vcf  annot=annot3
UNEVEN: sampleB  vcf=chr1.vcf  annot=annot1
UNEVEN: sampleB  vcf=chr2.vcf  annot=null
```
