import sys
import os
import re
import argparse

#going to pass arguments for the gbk path, new chromosome name
parser = argparse.ArgumentParser(description = "create fasta and gtf from gbk file")
parser.add_argument("--chrName",
                    type = str,
                    help="name of new chromosome and gtf and fasta files")
parser.add_argument("--gbk",
                    type = str,
                    help = "path to genbank file")

args = parser.parse_args()

if not os.path.exists(args.gbk):
    print("ERROR: The specified gbk file: " +
          args.gbk +
          " path does not exist!")
    sys.exit(1)


#store lines as list
with open(args.gbk, 'r') as file:
    lines = file.readlines()

#get where sequence starts
seq_start = []
for i in range(0, len(lines)):
    if "ORIGIN" in lines[i]:
        seq_start.append(i)

#get sequence
seqs=[]
for i in range(seq_start[0] + 1, len(lines) - 1):
    seqs.append(lines[i])

#make sequence one string and separate by ''
cds_seq=''.join(seqs)

#remove whitespace and newlines
cds_seq = cds_seq.replace(' ', '').replace('\n', '')
#remove digits and make all uppercase
cds_seq = re.sub(r'[0-9]', '', cds_seq).upper()

#write to fasta and add chromosome name
chr_name=args.chrName
with open(chr_name + ".fasta", "w") as file:
    file.write(">" + chr_name + "\n")
    file.write(cds_seq)

##write coding sequences to gtf
#first identify where coding sequences happen
cds_lines = []
for i in range(0, len(lines)):
    if "CDS" in lines[i] and "complement" not in lines[i]:
        cds_lines.append(i)

#store base pairs
bps=[]
labels = []
for cur_line in cds_lines:
    tmp_label=[]
    tmp_line = cur_line
    while not tmp_label:
        print(tmp_line)
        if "label" in lines[tmp_line]:
            tmp_label=lines[tmp_line].replace(" ", "").replace("/label=", "").replace("\n", "")
        tmp_line += 1
    #first remove CDS and all whitespace so we just have base pairs
    new_bps = lines[cur_line].replace(" ", "").replace("CDS", "").replace("\n", "").split("..")
    new_bps = [int(bp_num) for bp_num in new_bps]
    #add to element of list named for new label
    bps.append(new_bps)
    labels.append(tmp_label)

with open(chr_name + ".gtf", "w") as gtf:
    for i in range(0, len(labels)):
        gtf.write(chr_name +
                  "\tunknown\texon\t" +
                  str(bps[i][0]) +
                  "\t" +
                  str(bps[i][1]) +
                  "\t.\t+\t.\tgene_id " +
                  f'"{labels[i]}"' +
                  "; transcript_id " +
                  f'"{labels[i]}"; gene_biotype "protein_coding";\n')
        gtf.write(chr_name +
                  "\tunknown\ttranscript\t" +
                  str(bps[i][0]) +
                  "\t" +
                  str(bps[i][1]) +
                  "\t.\t+\t.\tgene_id " +
                  f'"{labels[i]}"' +
                  "; transcript_id " +
                  f'"{labels[i]}"; gene_biotype "protein_coding";\n')
        gtf.write(chr_name +
                  "\tunknown\tgene\t" +
                  str(bps[i][0]) +
                  "\t" +
                  str(bps[i][1]) +
                  "\t.\t+\t.\tgene_id " +
                  f'"{labels[i]}"' +
                  "; transcript_id " +
                  f'"{labels[i]}"; gene_biotype "protein_coding";\n')

# https://media.addgene.org/snapgene-media/v2.0.0/sequences/243367/aa7561a4-cb9c-461c-b805-c2df377ec5d1/addgene-plasmid-124372-sequence-243367.gbk