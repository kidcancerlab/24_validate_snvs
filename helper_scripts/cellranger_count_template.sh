#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=mk_counts_testing%j
#SBATCH --output=tmp_%j.txt
#SBATCH --error=tmp_%j.txt
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00
#SBATCH --wait

#store arguments as more descriptive variables
read -ra sra_array <<< "$1"
#get current sra
sra=${sra_array[$SLURM_ARRAY_TASK_ID]}
fastq_path=$2
out_dir=$3
ref=$4

#make output directory and folder for holding slurm output
mkdir -p $out_dir/output

#mv output file
mv tmp_$SLURM_JOBID.txt $out_dir/output/$sra.txt

#convert string of sras to array
# read -ra sra_array <<< "$1"

proj_name=$(basename $fastq_path)

# echo "sra job is $sra" 
# echo "project name is $proj_name" #0-$array_max
# echo "path to fastqs is $fastq_path"
# echo "data is output to $out_dir"
# echo "reference genome is $ref"

echo Running cellranger count for $sra
echo Output will be in $out_dir/$sra

cellranger count \
    --id $sra \
    --output-dir $out_dir/$sra \
    --fastqs $fastq_path/$sra \
    --localcores 20 \
    --transcriptome $ref \
    --nosecondary \
    --disable-ui \
    --create-bam true