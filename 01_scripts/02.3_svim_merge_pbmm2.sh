#!/bin/bash

# Merge refined svim SVs across samples with Jasmine

# manitou
# srun -c 10 -p medium --time=2-00:00:00 -J 02.3_svim_merge_pbmm2 --mem=100G -o log/02.3_svim_merge_pbmm2_%j.log /bin/sh ./01_scripts/02.3_svim_merge_pbmm2.sh &


# VARIABLES
GENOME="03_genome/genome.fasta"
CHR_BED="02_infos/chrs.bed.gz"
BAM_DIR="04_bam/pbmm2"
CALLS_DIR="05_calls/svim/pbmm2"
MERGED_DIR="06_merged/svim/pbmm2"
FILT_DIR="07_filtered/svim/pbmm2"

CPU=10

VCF_LIST_SVIM="$CALLS_DIR/vcf_list.txt" # list of svim VCFs files

# 1. Make a list of svim sample VCF files to merge
ls -1 $CALLS_DIR/*refined_dupToIns.vcf > $VCF_LIST_SVIM

# 2. Merge VCFs across samples 
jasmine file_list=$VCF_LIST_SVIM out_file="$MERGED_DIR/svim_PASS_refined.vcf" out_dir=$MERGED_DIR genome_file=$GENOME --ignore_strand --mutual_distance --allow_intrasample --output_genotypes --threads=$CPU

# 3. Convert INSs back to DUPs (out_file is the VCF to be postprocessed, will be modified in situ)
jasmine out_file="$MERGED_DIR/svim_PASS_refined.vcf" out_dir=$MERGED_DIR genome_file=$GENOME --threads=$CPU --dup_to_ins --postprocess_only


# Clean up
#rm 