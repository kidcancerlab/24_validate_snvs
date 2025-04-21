#!/bin/bash
#arguments:
#gbk file -g
#path to fastq folder -f
#species ? -s
#new chromosome/plasmid name -p
#folder for new reference -o

#Initialize variables
OPTIND=1
verbose=1
gbk=""
fastq_path=""
species="mm10"
plasmid=""
ref_out=""

while getopts "h?:g:f:s:p:o:" opt; do
    case "$opt" in
    h|\?)
        echo "Usage: $0 [-g gbk path] [-f fastq dir] [-s species (hg38 or mm10)] [-p plasmid]"
        exit 0
        ;;
    g)  gbk=$OPTARG
        ;;
    f)  fastq_path=$OPTARG
        ;;
    s)  species=$OPTARG
        ;;
    p)  plasmid=$OPTARG
        ;;
    o)  ref_out=$OPTARG
        ;;
    esac
done

ml cellranger


#make new reference directory
if [ -d $ref_out ]; then
    echo Specified output directory already exists. Skipping mkref and jumping to cellranger count
else
    mkdir $ref_out

    #make fastq and fasta for new plasmid
    python helper_scripts/make_gene_files.py --chrName $plasmid --gbk $gbk --outdir $ref_out

    #gtf and fasta are output to $ref_out/$chr_name.fa

    #copy over full gtf and fasta
    cp custom_ref/${species}_genes.gtf.gz $ref_out/genes.gtf.gz
    gunzip $ref_out/genes.gtf.gz

    cp custom_ref/${species}_genome.fa $ref_out/genome.fa

    chmod 774 $ref_out/*

    #cat new sequences to these files
    cat $ref_out/$plasmid.fa >> $ref_out/genome.fa
    cat $ref_out/$plasmid.gtf >> $ref_out/genes.gtf

    #make new reference
    cellranger mkref --output-dir $ref_out/ref_out \
        --genome $plasmid \
        --fasta $ref_out/genome.fa \
        --genes $ref_out/genes.gtf \
        --jobmode=local
fi

#make array of fastq folder names
fastqs=$(ls $fastq_path)

#separate fastq folders by space instea of newline
fastqs=$(tr "\n" " " <<< "$fastqs")

#get number of array jobs we'll have to submit (and subtract 1 bc it starts at 0)
array_max=$(($(wc -w <<< "$fastqs") - 1))

#have to pass the following arguments to sbatch script
# max number of array jobs: $array_max
# path to fastqs: $fastq_path/$fastqs
# reference genome: $ref_out/ref_out
# output directory: counts/$proj_name


#get name of project for counts folder
proj_name=$(basename $fastq_path)

sbatch --array 0-$(($array_max)) \
    helper_scripts/cellranger_count_template.sh \
    "$fastqs" \
    $fastq_path \
    counts/$proj_name \
    $ref_out/ref_out