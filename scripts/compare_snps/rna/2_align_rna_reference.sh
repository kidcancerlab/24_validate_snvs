#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=align_rna
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/bwa/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/bwa/logs/aligning_%A_%a.txt
#SBATCH --array=0-57
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00

set -euo pipefail

module load STAR/2.7.9a \
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
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
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

input_path=$wd_path/input/rna/${sample_type}/${accession}
output_path=$wd_path/output/rna/bwa/${sample_type}/${accession}

if [ ! -f "$input_path/${accession}_1.fastq" ]; then
    echo "Input file not found for sample ${sample_type} (${accession}). Skipping." >&2
    exit 0
fi

mkdir -p $wd_path/output/rna/bwa/${sample_type}/${accession}

# run alignment on human genome with STAR
STAR --genomeDir /reference/mus_musculus/GRCm38/ensembl/release-86/Sequence/STARIndex_2.7.9a \
--runThreadN 6 \
--readFilesIn $input_path/${accession}_1.fastq $input_path/${accession}_2.fastq \
--outFileNamePrefix $output_path/${accession}_ \
--outSAMtype BAM SortedByCoordinate \
--twopassMode Basic \
--outSAMunmapped Within \
--outSAMattributes NH HI AS nM NM MD

# mark duplicates
java -jar picard.jar MarkDuplicates \
    -I $output_path/${accession}_Aligned.sortedByCoord.out.bam \
    -O $output_path/${accession}_markdup.bam \
    -M $output_path/${accession}_markdup_metrics.txt

# split N cigar reads



samtools index -@ 2 $output_path/${accession}_Aligned.sortedByCoord.out.bam

samtools flagstat -@ 2 $output_path/${accession}_Aligned.sortedByCoord.out.bam \
    > "$output_path/${accession}_flagstat.txt"

samtools stats -@ 2 $output_path/${accession}_Aligned.sortedByCoord.out.bam \
    > "$output_path/${accession}_stats.txt"