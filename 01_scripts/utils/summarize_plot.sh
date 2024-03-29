#!/bin/bash

# Plot merged SVs to compare counts by type, length and caller (LR)

# manitou 
# srun -p small -c 1 -J summarize_plot -o log/summarize_plot_%j.log /bin/sh 01_scripts/utils/summarize_plot.sh &

# valeria 
# srun -p ibis_small -c 1 -J summarize_plot -o log/summarize_plot_%j.log /bin/sh 01_scripts/utils/summarize_plot.sh &

# VARIABLES
GENOME="03_genome/genome.fasta"
CALLS_DIR="05_calls"
FILT_DIR="07_filtered"

MERGED_UNION_DIR="08_merged_union"
FILT_UNION_DIR="09_filtered_union"

SNIFFLES_VCF="$FILT_DIR/sniffles/sniffles_PASS_PRECISE.vcf"
SVIM_VCF="$FILT_DIR/svim/svim_PASS.vcf"
NANOVAR_VCF="$FILT_DIR/nanovar/nanovar_PASS.vcf"

VCF_LIST="02_infos/callers_VCFs.txt"
MERGED_VCF="$MERGED_UNION_DIR/merged_sniffles_svim_nanovar.vcf"

REGIONS_EX="02_infos/excl_chrs.txt"

FILT_VCF="$FILT_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)"_SUPP2.vcf"

# LOAD REQUIRED MODULES
module load bcftools/1.13
module load R/4.1

# 1. Extract fields for both merged and filtered VCFs
bcftools query -f '%CHROM\t%POS\t%ID\t%SVTYPE\t%SVLEN\t%END\t%SUPP\t%SUPP_VEC\n' $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".sorted.vcf > $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".table

bcftools query -f '%CHROM\t%POS\t%ID\t%SVTYPE\t%SVLEN\t%END\t%SUPP\t%SUPP_VEC\n' $FILT_VCF > $FILT_UNION_DIR/"$(basename -s .vcf $FILT_VCF)".table


# 2. Run plotting script
Rscript 01_scripts/utils/summarize_plot_SVs.R $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".table $FILT_UNION_DIR/"$(basename -s .vcf $FILT_VCF)".table 'sniffles' 'svim' 'nanovar'