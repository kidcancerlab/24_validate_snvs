import argparse
from pysam import VariantFile
import numpy as np


parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--bcf',
                    type = str,
                    default=  'test.bcf',
                    help = 'BCF file with multiple samples as columns')
parser.add_argument('--threads',
                    '-t',
                    type = int,
                    default = 1,
                    help = 'Number of threads to use')
parser.add_argument('--verbose',
                    '-v',
                    action = 'store_true',
                    help = 'print out extra information')

args = parser.parse_args()


################################################################################
### Code

# We'll be getting the GT field to get the genotypes (ref/alt) then getting the
# AD field to get the read depth for each allele
# DP field to get total depth at position, this is ultimately what we filter on
# I want:
#   For each position, total number of reads for each depth in DP value
#   Number of positions where an alt allele was called
#   Do I want to split het/homozygous positions?
# I can make a dict where
# alt_dict[depth][sites_covered] = X
# alt_dict[depth][genotype] = Y

def main():
    alt_dict = get_prop_alt(args.bcf)

    if args.verbose: print('Printing output')
    print_proportion_alt(alt_dict)

    return


def get_prop_alt(bcf_file):
    if args.verbose: print('Reading BCF')
    samples, records = get_samps_records(bcf_file, args.threads)

    if args.verbose: print('Getting genotypes')
    genotypes = get_genotypes(records, samples)

    if args.verbose: print('Getting depths')
    depths = get_depths(records, samples)

    if args.verbose: print('Making alt_dict')
    alt_dict = make_alt_dict(genotypes, depths)

    return alt_dict

def get_samps_records(bcf_file, threads):
    bcf_in = VariantFile(bcf_file, threads = threads)

    samples = tuple(bcf_in.header.samples)

    records = tuple(x for x in list(bcf_in.fetch()))

    bcf_in.close()
    return samples, records

def get_genotypes(records, samples):
    genotypes = np.array([
        [''.join(map(str, rec.samples[sample]['GT'])) for sample in samples if ''.join(map(str, rec.samples[sample]['GT'])) != 'NoneNone']
        for rec in records
    ]).flatten()

    return genotypes

def get_depths(records, samples):
    depths = np.array([
        [str(rec.samples[sample]['DP']) for sample in samples if rec.samples[sample]['DP'] != 'None']
        for rec in records
    ]).flatten()
    #depths = depths[depths != 'None']

    return depths

def make_alt_dict(genotypes, depths):
    alt_dict = {}
    alt_dict = count_pos_covered(depths, alt_dict)

    # Count sites for each genotype by depth
    alt_dict = count_gt_by_depth(genotypes, depths, alt_dict)

    return alt_dict

def count_pos_covered(depths, alt_dict):
    depth_categories, counts = np.unique(depths, return_counts = True)

    for i in range(len(counts)):
        alt_dict[depth_categories[i]] = {}
        alt_dict[depth_categories[i]]['sites_covered'] = counts[i]

    return alt_dict

def count_gt_by_depth(genotypes, depths, alt_dict):
    for i in range(len(genotypes)):
        this_genotype = genotypes[i]
        this_depth = depths[i]
        if this_genotype in alt_dict[this_depth].keys():
            alt_dict[this_depth][this_genotype] += 1
        else:
            alt_dict[this_depth][this_genotype] = 1
    return alt_dict

def print_proportion_alt(alt_dict):
    depth_categories = tuple(alt_dict.keys())
    print('depth\tsites_cov\tgt_00\tgt_01\tgt_11')

    for this_depth_cat in depth_categories:
        # we're ignoring sites with odd genotypes like 0/2
        # This will print out None for missing data
        print(
            this_depth_cat,
            '\t',
            alt_dict[this_depth_cat].get('sites_covered', 0),
            '\t',
            alt_dict[this_depth_cat].get('00', 0),
            '\t',
            alt_dict[this_depth_cat].get('01', 0),
            '\t',
            alt_dict[this_depth_cat].get('11', 0)
        )
    return

if __name__ == '__main__':
    main()
