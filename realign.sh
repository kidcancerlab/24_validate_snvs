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

#make new reference directory
mkdir $ref_out

#make fastq and fasta for new plasmid
python make_gene_files.py --chrName $plasmid --gbk $gbk --outdir $ref_out

#gtf and fasta are output to $ref_out/$chr_name.fa

#make new reference now
#copy over full gtf and fasta
cp custom_ref/${species}_genes.gtf.gz $ref_out/genes.gtf.gz
gunzip $ref_out/genes.gtf.gz

cp custom_ref/${species}_genome.fa $ref_out/genome.fa

chmod 774 $ref_out/*

#cat new sequences to these files
cat $ref_out/$plasmid.fa >> $ref_out/genome.fa
cat $ref_out/$plasmid.gtf >> $ref_out/genes.gtf