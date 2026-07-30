#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_exome
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/bwa/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/bwa/logs/aligning_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=05:00:00

module load bwa-mem2/2.2.1 SAMtools/1.15

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/


sample=(
    SRR13611861 # F420 cell line exome
    SRR13611860 # K7M2 cell line exome
    SRR27799014 # Balbc exome
    SRR27799015 # B6 exome
)

# first align to reference mm10, BL6
# then, correct any flaw in read-pairing introduced from aligner
# then, sort to genome chromosome and coordinate
bwa-mem2 mem -M -t 2 \
    $wd_path/input/reference/reference \
    $wd_path/input/exome/${sample}_1.fastq $wd_path/input/exome/${sample}_2.fastq \
    | samtools fixmate -m -@ 2 - - \
    | samtools sort -@ 2 -m 2G -T $wd_path/output/bwa/tmp_${sample} - \
    | samtools markdup -@ 2 --write-index -o $wd_path/output/bwa/${sample}_markdup.bam - \

samtools flagstat -@ 2 $wd_path/output/bwa/${sample}_markdup.bam \
    > $wd_path/output/bwa/${sample}_flagstat.txt

samtools stats -@ 2 $wd_path/output/bwa${sample}_markdup.bam \
    > $wd_path/output/bwa/${sample}_stats.txt
