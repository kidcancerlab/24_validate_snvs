#!/bin/sh
#SBATCH --output=input/othertumors/slurmout/geo_count-%j.out
#SBATCH --error=input/othertumors/slurmout/geo_count-%j.out
#SBATCH --job-name=geo_count
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --wait

set -e

sample_array=($( \
    cut -f 3,8 misc/validation_geo_metadata.tsv \
    | uniq \
    | grep -v Sample_ID \
    | cut -f 1\
))

ref_array=($( \
    cut -f 3,8 misc/validation_geo_metadata.tsv \
    | uniq \
    | grep -v Sample_ID \
    | cut -f 2
))

this_sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}
this_ref=${ref_array[${SLURM_ARRAY_TASK_ID}]}

echo ${this_sample} ${this_ref}

if [ ! -d output/cellranger_out/${this_sample} ]
then
    mkdir -p output/cellranger_out/${this_sample}
fi

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

cellranger count \
  --id ${this_sample} \
  --fastqs input/othertumors/fastqs/${this_sample}/ \
  --sample ${this_sample} \
  --transcriptome ${this_ref} \
  --localcores 10 \
  --expect-cells 8000 \
  --nosecondary \
  --disable-ui \
  --output-dir output/cellranger_out/${this_sample}

rm output/cellranger_out/${this_sample}/_*

rm -r output/cellranger_out/${this_sample}/SC_RNA_COUNTER_CS

rm output/cellranger_out/${this_sample}/${this_sample}.mri.tgz

mv \
    output/cellranger_out/${this_sample}/outs/* \
    output/cellranger_out/${this_sample}/

rmdir output/cellranger_out/${this_sample}/outs
