#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=align_exome
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/exome/bwa/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/exome/bwa/logs/aligning_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00

set -euo pipefail

module load bwa-mem2/2.2.1 \
    SAMtools/1.15

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
## -t => skips trailing newline character as it reads each line
## <() => process substitution; runs command inside () as if it were file
## cut => extract columns from tsv
## -f1 => field 1 or first column
mapfile \
    -t \
    sample_types \
    < \
    <(cut \
        -f2 \
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "Processing $sample_type ($accession)"

# first align to reference mm10, BL6
## ran bwa-mem2 index on the mm10.fa separately; this makes the bwa-mem2 index files

# then, correct any flaw in read-pairing introduced from aligner
## with samtools fixmate

# then, sort to genome chromosome and coordinate
## with samtools sort

# then, mark PCR or read duplicates
## with samtools markdup

# then, get stats!

mkdir -p $wd_path/output/exome/bwa/${sample_type}/${accession}

input_path=$wd_path/input/exome/${sample_type}/${accession}
output_path=$wd_path/output/exome/bwa/${sample_type}/${accession}

bwa-mem2 mem \
        -M -t 10 \
    $wd_path/input/reference/reference \
    $input_path/${accession}_1.fastq \
    $input_path/${accession}_2.fastq \
    | samtools fixmate \
        -m \
        -@ 5 - - \
    | samtools sort \
        -@ 5 \
        -m 2G \
        -T \
        $output_path/tmp_${accession} - \
    | samtools markdup \
        -@ 5 \
        --write-index \
        - \
        $output_path/${accession}_markdup.bam

samtools flagstat -@ 2 $output_path/${accession}_markdup.bam \
    > $output_path/${accession}_flagstat.txt

samtools stats -@ 2 $output_path/${accession}_markdup.bam \
    > $output_path/${accession}_stats.txt
