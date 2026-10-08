#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=align_rna
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/bwa/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/bwa/logs/aligning_%A_%a.txt
#SBATCH --array=0-29
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00

set -euo pipefail

module load STAR/2.7.9a \
    SAMtools/1.15 \
    GATK/4.5.0.0-Java-17.0.2

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
## -t => skips trailing newline character as it reads each line
## <() => process substitution; runs command inside () as if it were file
## cut => extract columns from tsv
## -f1 => field 1 or first column
sample_types=($(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))
SRR_IDs=($(cut \
        -f1 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "**Processing $sample_type ($accession)"

# first align to reference mm10, BL6
## ran bwa-mem2 index on the mm10.fa separately; this makes the bwa-mem2 index files

# then, correct any flaw in read-pairing introduced from aligner
## with samtools fixmate

# then, sort to genome chromosome and coordinate
## with samtools sort

# then, mark PCR or read duplicates
## with samtools markdup

# then, get stats!

if [[ $accession == SRR* ]]; then
    input_path=$wd_path/input/rna/${sample_type}/${accession}
    output_path=$wd_path/output/rna/bwa/${sample_type}/${accession}

    r1=$input_path/${accession}_1.fastq.gz
    r2=$input_path/${accession}_2.fastq.gz

    echo "r1 is ${r1} and r2 is ${r2}"

    if [ ! -f ${r1} ]; then
        echo "Input file not found for sample ${sample_type} (${accession}). Skipping." >&2
        exit 0
    fi

    mkdir -p $wd_path/output/rna/bwa/${sample_type}/${accession}

else
    input_path=$wd_path/input/rna/${sample_type}
    output_path=$wd_path/output/rna/bwa/${sample_type}

    mkdir -p $wd_path/output/rna/bwa/${sample_type}

    r1=$(ls "$input_path"/${sample_type}_S*_L00*_R1_001.fastq.gz | paste -sd,)
    r2=${r1//_R1_001/_R2_001}

fi

STAR --genomeDir /reference/mus_musculus/GRCm38/ensembl/release-86/Sequence/STARIndex_2.7.9a \
    --runThreadN 6 \
    --readFilesIn "$r1" "$r2" \
    --readFilesCommand zcat \
    --outSAMattrRGline ID:${accession} SM:${accession} PL:ILLUMINA \
    --outFileNamePrefix $output_path/${accession}_ \
    --outSAMtype BAM Unsorted \
    --twopassMode Basic \
    --outSAMunmapped Within \
    --outSAMattributes NH HI AS nM NM MD

echo "**Finished aligning, marking duplicates"

samtools collate -@ 6 -O -u "$output_path"/${accession}_Aligned.out.bam "$output_path"/${accession}_collate_tmp \
  | samtools fixmate -@ 6 -m -u - - \
  | samtools sort -@ 6 -u -T "$output_path"/${accession}_sort_tmp - \
  | samtools markdup -@ 6 - "$output_path"/${accession}_markdup.bam

samtools index "$output_path"/${accession}_markdup.bam

# # mark duplicates
# ## identifies reads from same original fragment and flags them
# gatk MarkDuplicates \
#     -I $output_path/${accession}_Aligned.sortedByCoord.out.bam \
#     -O $output_path/${accession}_markdup.bam \
#     -M $output_path/${accession}_markdup_metrics.txt

# samtools index -@ 2 $output_path/${accession}_markdup.bam

# echo "**Finished marking duplicates, splitting CIGAR string"

# # split N cigar reads
# ## splits reads spanning splice junctions into separate reads
# ## so that variant callers built for DNA can handle them
# gatk SplitNCigarReads \
#     -R $wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa \
#     -I $output_path/${accession}_markdup.bam \
#     -O $output_path/${accession}_split.bam

# echo "**Finally, running stats"

# samtools index -@ 2 $output_path/${accession}_split.bam

# samtools flagstat -@ 2 $output_path/${accession}_split.bam \
#     > "$output_path/${accession}_flagstat.txt"

# samtools stats -@ 2 $output_path/${accession}_split.bam \
#     > "$output_path/${accession}_stats.txt"