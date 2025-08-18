#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/fp_ref-%j.out
#SBATCH --error=slurmOut/fp_ref-%j.out
#SBATCH --job-name=fp_ref
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --partition=general,himem
#SBATCH --time=12:00:00
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

## Update Reference Genome

# I need to add the fluorescent reporter sequences to our reference genome before aligning our fastqs. I'll be adding it to our 10x-mm10 reference genome.

### eGFP
# I will first need to create a file named eGFP.fa containing the nucleotide sequence for our GFP protein.
#get number of bases in GFP.fa

#lets make a custom gtf for gfp; \t helps us make new columns that are needed in the gtf; we need both the exon and transcript lines
# 720 bases
echo -e \
'eGFP\tunknown\texon\t1\t720\t.\t+\t.\tgene_id "tumor_eGFP"; transcript_id "tumor_eGFP"; gene_biotype "protein_coding";\n'\
'eGFP\tunknown\ttranscript\t1\t720\t.\t+\t.\tgene_id "tumor_eGFP"; transcript_id "tumor_eGFP"; gene_biotype "protein_coding";\n'\
'eGFP\tunknown\tgene\t1\t720\t.\t+\t.\tgene_id "tumor_eGFP"; gene_name "tumor_eGFP"; gene_biotype "protein_coding";'\
    > custom_ref/eGFP.gtf

### RFP also known as dsRed
#672 bases

echo -e \
'RFP\tunknown\texon\t1\t672\t.\t+\t.\tgene_id "tumor_RFP"; transcript_id "tumor_RFP"; gene_biotype "protein_coding";\n'\
'RFP\tunknown\ttranscript\t1\t672\t.\t+\t.\tgene_id "tumor_RFP"; transcript_id "tumor_RFP"; gene_biotype "protein_coding";\n'\
'RFP\tunknown\tgene\t1\t672\t.\t+\t.\tgene_id "tumor_RFP"; gene_name "tumor_RFP"; gene_biotype "protein_coding";'\
    > custom_ref/RFP.gtf

### Make the combined reference files
cat \
    custom_ref/eGFP.fa \
    custom_ref/RFP.fa \
    /home/gdrobertslab/lab/GenRef/10x-mm10/fasta/genome.fa \
    > custom_ref/gfp_rfp_mm10_genome.fa

cp /home/gdrobertslab/lab/GenRef/10x-mm10/genes/genes.gtf.gz .
gunzip genes.gtf.gz

cat \
    genes.gtf \
    custom_ref/eGFP.gtf \
    custom_ref/RFP.gtf \
    > custom_ref/gfp_rfp_mm10_genes.gtf

rm genes.gtf

#Time to make our new reference using cellranger mkref
cellranger mkref \
    --output-dir custom_ref/gfp_rfp_mm10 \
    --genome gfp_rfp_mm10 \
    --fasta custom_ref/gfp_rfp_mm10_genome.fa \
    --genes custom_ref/gfp_rfp_mm10_genes.gtf \
    --jobmode=local \
    --localcores 5
