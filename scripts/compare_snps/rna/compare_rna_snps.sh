#!/bin/bash
# run this: bash compare_snps.sh

script_dir="/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/scripts/compare_snps/rna"

load_rna_jid=$(sbatch \
    --parsable \
    "$script_dir"/1_load_rna_data.sh)

align_rna_jid=$(sbatch \
    --parsable \
    --dependency=afterok:$load_rna_jid \
    "$script_dir"/2_align_rna_reference.sh)

run_variant_jid=$(sbatch \
    --parsable \
    --dependency=afterok:$align_rna_jid \
    "$script_dir"/3_run_rna_variant.sh)

echo "Pipeline submitted: \
    load_rna=$load_rna_jid \
    align_rna=$align_rna_jid \
    run_variant=$run_variant_jid"