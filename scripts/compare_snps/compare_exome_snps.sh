#!/bin/bash
# run this: bash compare_snps.sh

script_dir="/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/scripts"

load_exome_jid=$(sbatch \
    --parsable \
    "$script_dir"/1_load_exome_data.sh)

align_exome_jid=$(sbatch \
    --parsable \
    --dependency=afterok:$load_exome_jid \
    "$script_dir"/2_align_exome_reference.sh)

run_variant_jid=$(sbatch \
    --parsable \
    --dependency=afterok:$align_exome_jid \
    "$script_dir"/3_run_exome_variant.sh)

echo "Pipeline submitted: \
    load_exome=$load_exome_jid \
    align_exome=$align_exome_jid \
    run_variant=$run_variant_jid"