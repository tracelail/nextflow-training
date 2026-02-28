# Session 9 — Expected Outputs

## Exercise 1 (01_basic_operators.nf)

After Steps 1–2 (base file, no samplesheet):
```
Squared: 1
Squared: 4
Squared: 9
Squared: 16
Squared: 25
File: genes
Even: 2
Even: 4
Even: 6
Even: 8
Even: 10
Flattened: 1
Flattened: 2
Flattened: 3
Flattened: 4
Flattened: 5
Flattened: 6
All words: [alpha, beta, gamma, delta]
```

After Step 3 (add samplesheet parsing, 6 samples):
```
Sample: SAMPLE_A (tumor)
Sample: SAMPLE_B (tumor)
Sample: SAMPLE_C (tumor)
Sample: SAMPLE_D (normal)
Sample: SAMPLE_E (normal)
Sample: SAMPLE_F (normal)
```

After Step 4 (add .filter for tumors only, 3 samples):
```
Sample: SAMPLE_A (tumor)
Sample: SAMPLE_B (tumor)
Sample: SAMPLE_C (tumor)
```

---

## Exercise 2 (02_intermediate_operators.nf)

Branch output (3 tumor, 3 normal):
```
TUMOR:  SAMPLE_A
TUMOR:  SAMPLE_B
TUMOR:  SAMPLE_C
NORMAL: SAMPLE_D
NORMAL: SAMPLE_E
NORMAL: SAMPLE_F
```

Inner join (only A and B have matches in both channels):
```
Inner:  SAMPLE_A score=42 flag=PASS
Inner:  SAMPLE_B score=87 flag=FAIL
```

Outer join (all 4 unique IDs appear, with nulls for missing data):
```
Outer:  SAMPLE_A score=42   flag=PASS
Outer:  SAMPLE_B score=87   flag=FAIL
Outer:  SAMPLE_C score=61   flag=null
Outer:  SAMPLE_D score=null flag=PASS
```

multiMap (6 lines each):
```
Meta:  SAMPLE_A (tumor)
Meta:  SAMPLE_B (tumor)
...
Reads: SAMPLE_A
Reads: SAMPLE_B
...
```

collectFile:
```
Written: /path/to/results/sample_summary.tsv
```

cat results/sample_summary.tsv:
```
SAMPLE_A	tumor	treated
SAMPLE_B	tumor	treated
SAMPLE_C	tumor	untreated
SAMPLE_D	normal	treated
SAMPLE_E	normal	treated
SAMPLE_F	normal	untreated
```
(order of rows may vary)

---

## Exercise 3 (03_scatter_gather.nf)

Scattered lines (12 total — 3 tumor samples × 4 intervals):
```
Scattered: SAMPLE_A x chr1:1-10000
Scattered: SAMPLE_A x chr2:1-10000
Scattered: SAMPLE_A x chr3:1-10000
Scattered: SAMPLE_A x chrX:1-10000
Scattered: SAMPLE_B x chr1:1-10000
... (12 lines total)
```

Task count from `nextflow log last -f 'process,tag,status'`:
- 12 × CALL_VARIANTS tasks
- 3 × MERGE_VCFS tasks
- 15 tasks total

Gathered lines (3 total):
```
Gathered SAMPLE_A: 4 VCFs
Gathered SAMPLE_B: 4 VCFs
Gathered SAMPLE_C: 4 VCFs
```

Final merged files in results/merged/:
```
SAMPLE_A_merged.txt
SAMPLE_B_merged.txt
SAMPLE_C_merged.txt
```

cat results/merged/SAMPLE_A_merged.txt:
```
Sample: SAMPLE_A
Merged VCFs: SAMPLE_A_chr1:1-10000.vcf, SAMPLE_A_chr2:1-10000.vcf, SAMPLE_A_chr3:1-10000.vcf, SAMPLE_A_chrX:1-10000.vcf
```
