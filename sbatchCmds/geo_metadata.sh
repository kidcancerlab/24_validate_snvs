#!/bin/sh
#SBATCH --account=gdkendalllab
#SBATCH --array=0-40%1
#SBATCH --error=slurmOut/meta-%j.txt
#SBATCH --output=slurmOut/meta-%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name meta
#SBATCH --wait
#SBATCH --time=0-12:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=ALL

set -e ### stops bash script if line ends with error

ml purge
ml load edirect/default

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

geo_array=($(tail -n +2 misc/Labs_and_GEOs.txt | cut -f 2))
geo=${geo_array[${SLURM_ARRAY_TASK_ID}]}

geo_stub=$(echo ${geo} | perl -pe 's/\d\d\d$/nnn/')

# Get GEO study metadata
wget \
    -P output/geo_meta/geo_metadata/ \
    ftp://ftp.ncbi.nlm.nih.gov/geo/series/${geo_stub}/${geo}/soft/*

# Get SRA IDs from GEO
# Note that these SRAs cannot be used to download the data, need to get more info
esearch \
    -db gds \
    -query ${geo} \
    | efetch -format docsum \
    | xtract \
        -pattern ExtRelation \
        -element TargetObject \
    | awk -v geo=${geo} '{print $_ "\t" geo}' \
    > output/ids/SRA/geo_srx_${geo}.txt

# Get SRA IDs I can use to download the data and save file with columns to match
# with GEO IDs
sras=$(cut -f 1 output/ids/SRA/geo_srx_${geo}.txt \
        | perl -pe 's/\n/ OR /' \
        | perl -pe 's/ OR $//')

esearch -db sra -query "${sras}" \
    | efetch -format docsum \
    | xtract \
        -pattern DocumentSummary \
        -element Bioproject,\
                 Biosample,\
                 Run@acc \
    > output/ids/SRA/srr_plus_${geo}.txt

esearch -db sra -query "${sras}" \
    | efetch -format docsum \
    | xtract \
        -pattern DocumentSummary \
        -element Bioproject,\
                 Biosample,\
                 Organism@ScientificName,\
                 Experiment@name,\
                 LIBRARY_STRATEGY,\
                 Platform@instrument_model \
    > output/ids/SRA/srr_metadata_${geo}.txt

sleep 1