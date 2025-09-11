import argparse
import sys
from pysam import VariantFile
import numpy as np

################################################################################
### Code

def main():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--bcf',
                        type = str,
                        default=  'test.bcf',
                        help = 'BCF file with multiple samples as columns')
    parser.add_argument('--max_prop_missing',
                        type = float,
                        default = 0.75,
                        help = 'max proportion of missing data allowed at a single locus')
    parser.add_argument('--verbose',
                        action = 'store_true',
                        help = 'print out extra information')
    parser.add_argument('--processes',
                        '-p',
                        type = int,
                        default = 1,
                        help = 'number of processes to use for parallel processing')

    args = parser.parse_args()

    n_shared_pos, samples = get_n_shared_pos_from_bcf(
        args.bcf,
        args.max_prop_missing,
        args.processes)

    print('cell_1', *samples, sep = '\t')

    for i in range(n_shared_pos.shape[0]):
        print(samples[i], end = '\t')
        print(*n_shared_pos[i, :], sep = '\t')

    if args.verbose:
        print("Done!", file=sys.stderr)
    return


########
### functions

####### Can I clear out genotypes with all missing data? #################
def get_n_shared_pos_from_bcf(bcf_file,
                              max_prop_missing,
                              threads):
    dist_key_dict = {'00':            1,
                     '01':            2,
                     '10':            4,
                     '11':            8,
                     '(None, None)':  0}
    ### Check if bcf index exists
    bcf_in = VariantFile(bcf_file, threads = threads)
    samples = tuple(bcf_in.header.samples)

    records = tuple(x for x in list(bcf_in.fetch()) if x.alts is not None)
    bcf_in.close()

    # Precompute the genotype tuples for all samples
    genotype_tuples = np.array([
        [tuple(pad_len_1_genotype(rec.samples[sample]['GT'])) for sample in samples]
        for rec in records
    ])

    # Convert genotype tuples to strings and look up in dist_key_dict
    # Rows are sites and columns are samples
    genotype_matrix = np.array([
        [dist_key_dict.get(''.join(map(str, gt)), np.nan) for gt in sample_genotypes]
        for sample_genotypes in genotype_tuples
    ])

    # Filter out variant positions seen in less than x% of samples
    #!!! I don't think I want to do this since the question I'm asking is how
    #!!! many variant positions have shared data between cells
    #percent_missing = np.sum(np.isnan(genotype_matrix), axis=1) / len(samples)
    #genotype_matrix = genotype_matrix[percent_missing <= max_prop_missing]

    sum_per_site = \
        genotype_matrix[:, :, np.newaxis] + \
        genotype_matrix[:, np.newaxis, :]

    # This is getting rid of sites where both samples are reference and not informative
    sum_per_site[sum_per_site == 2] = np.nan

    # This makes it so that when we sum up across sites, we get the number of shared sites
    sum_per_site[sum_per_site > 2] = 1

    # The upper triangle is a matrix of sum where rows and columns are samples
    # The diagonal is the number of sites per sample
    n_shared_pos = np.apply_along_axis(np.nansum, 0, sum_per_site)

    return n_shared_pos, samples

def pad_len_1_genotype(gt):
    if len(gt) == 1:
        return (gt[0], 0)

    return gt

################################################################################
### main

if __name__ == '__main__':
    main()
