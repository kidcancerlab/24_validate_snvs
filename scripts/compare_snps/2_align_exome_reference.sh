#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_exome
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/bwa/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/bwa/logs/aligning_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00

set -euo pipefail

module load bwa-mem2/2.2.1 SAMtools/1.15

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# F420 cell line exome
# K7M2 cell line exome
# Balbc exome
# B6 exome

sample_array=(
    SRR13611861
    SRR13611860
    SRR27799014
    SRR27799015
)

sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}

echo ${sample}

# first align to reference mm10, BL6
## ran bwa-mem2 index on the mm10.fa separately; this makes the bwa-mem2 index files

# then, correct any flaw in read-pairing introduced from aligner
## with samtools fixmate

# then, sort to genome chromosome and coordinate
## with samtools sort

# then, mark PCR or read duplicates
## with samtools markdup

# then, get stats!

bwa-mem2 mem \
        -M -t 10 \
    $wd_path/input/reference/reference \
    $wd_path/input/exome/${sample}_1.fastq \
    $wd_path/input/exome/${sample}_2.fastq \
    | samtools fixmate \
        -m \
        -@ 5 - - \
    | samtools sort \
        -@ 5 \
        -m 2G \
        -T \
        $wd_path/output/bwa/tmp_${sample} - \
    | samtools markdup \
        -@ 5 \
        --write-index \
        - \
        $wd_path/output/bwa/${sample}_markdup.bam

samtools flagstat -@ 2 $wd_path/output/bwa/${sample}_markdup.bam \
    > $wd_path/output/bwa/${sample}_flagstat.txt

samtools stats -@ 2 $wd_path/output/bwa/${sample}_markdup.bam \
    > $wd_path/output/bwa/${sample}_stats.txt
