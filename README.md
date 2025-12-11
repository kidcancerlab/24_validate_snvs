# Validation of the scanBit tool

ScanBit is a tool designed to identify genetically distinct populations of cells within scRNAseq datasets. This repository is dedicated to validating the performance and accuracy of the scanBit tool through various tests and benchmarks. This is the data supporting the scanBit publication: "SCANBIT facilitates identification of tumor cell populations in scRNAseq data using pseudobulked SNV calls".

## Validation tests

- **Variant Calling on 10x Flex Data**:
  - Quantify sequencing error rates at varying read depths using 10x Genomics datasets.

- **Mouse Strain Clustering**:
  - Validate clustering accuracy for genetically distinct mouse strains (e.g., B6 vs. Balb/c).

- **Tumor Marker Validation**:
  - Assess accuracy of tumor cell identification using known markers (e.g., GFP, RFP, LTBC).

- **Host-Tumor Genetic Divergence**:
  - Simulate patient-like scenarios where tumor cells derive from the host mouse strain.

- **Human Patient Tumor Samples**:
  - Assess scanBit results on human tumor datasets from GEO.

- **Downsampling Analysis**:
  - Test the minimum number of cells/reads needed for accurate identification of distinct populations.
  - Quantify read depth coverage for single-cell downsampling.

- **Run Time and RAM Usage**:
  - Quantify average computational resource usage for the pipeline.

## Data availability

The data used in this repository comes from a variety of publicly available and internally generated sources including 10x Genomics datasets, GEO and internal experiments. Scripts to download the data are provided in the sbatchCmds/ folder.
