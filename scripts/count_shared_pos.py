import argparse
import sys
import multiprocessing
from itertools import repeat, chain
from pysam import VariantFile
import numpy as np
from scipy.cluster.hierarchy import linkage, dendrogram
from scipy.spatial.distance import squareform
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('pdf')

################################################################################
### Code

def main():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--bcf',
                        type = str,
                        default=  'output/read_depth/scanbit_out/x_samples/X00001/downsample_1_cells/mergeddownsample_X00001_1_c1.bcf',
                        help = 'BCF file with multiple samples as columns')
    parser.add_argument('--min_snvs_for_cluster',
                        type = int,
                        default = 1000,
                        help = 'minimum number of SNVs for a cluster to be included')
    parser.add_argument('--max_prop_missing',
                        type = float,
                        default = 0.9,
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
        args.min_snvs_for_cluster,
        args.max_prop_missing,
        args.processes)

    if args.verbose:
        print("Done!", file=sys.stderr)
    return


########
### functions

####### Can I clear out genotypes with all missing data? #################
def get_n_shared_pos_from_bcf(bcf_file,
                             min_snvs_for_cluster,
                             max_prop_missing,
                             threads):
    dist_key_dict = {'00':            0.5,
                     '01':            0.5,
                     '10':            0.5,
                     '11':            0.5,
                     '(None, None)':  0}
    ### Check if bcf index exists
    bcf_in = VariantFile(bcf_file, threads = threads)
    samples = tuple(bcf_in.header.samples)
    records = tuple(x for x in list(bcf_in.fetch()) if (len(x.alts) == 1))
    bcf_in.close()

    # Precompute the genotype tuples for all samples
    genotype_tuples = np.array([
        [tuple(pad_len_1_genotype(rec.samples[sample]['GT'])) for sample in samples]
        for rec in records
    ])

    # Convert genotype tuples to strings and look up in dist_key_dict
    genotype_matrix = np.array([
        [dist_key_dict.get(''.join(map(str, gt)), np.nan) for gt in sample_genotypes]
        for sample_genotypes in genotype_tuples
    ])

    # Filter out variant positions seen in less than x% of samples
    percent_missing = np.sum(np.isnan(genotype_matrix), axis=1) / len(samples)
    genotype_matrix = genotype_matrix[percent_missing <= max_prop_missing]

    differences = np.abs(genotype_matrix[:, :, np.newaxis]
                         + genotype_matrix[:, np.newaxis, :])

    n_shared_pos = np.apply_along_axis(np.nansum, 0, differences)

    return n_shared_pos, samples

def pad_len_1_genotype(gt):
    if len(gt) == 1:
        return (gt[0], 0)
    else:
        return gt


################################################################################
### main

if __name__ == '__main__':
    main()
