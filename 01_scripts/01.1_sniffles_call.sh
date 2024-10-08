#!/bin/bash

# Call SVs with sniffles2 across whole genome, including unplaced contigs which will be removed after

# parallel -a 02_infos/ind_PB.txt -j 4 srun -c 4 -p small --time=1-00:00:00 -J 01.1_sniffles_call_{} --mem=15G -o log/01.1_sniffles_call_{}_%j.log /bin/sh ./01_scripts/01.1_sniffles_call.sh {} &

# VARIABLES
SAMPLE=$1

GENOME="03_genome/genome.fasta"
CHR_BED="02_infos/chrs.bed.gz"
BAM_DIR="04_bam"
CALLS_DIR="05_calls"
MERGED_DIR="06_merged"
FILT_DIR="07_filtered"

BAM="$BAM_DIR/"$SAMPLE".ccs.bam"

CPU=4

# LOAD REQUIRED MODULES
module load bcftools/1.15


# 0. Create output dir
if [[ ! -d "$CALLS_DIR/sniffles/$SAMPLE" ]]
then
  mkdir "$CALLS_DIR/sniffles/$SAMPLE"
fi

# 1. Call SVs in whole genome
sniffles --input $BAM --vcf $CALLS_DIR/sniffles/$SAMPLE/"$SAMPLE"_all_contigs.vcf.gz --snf $CALLS_DIR/sniffles/$SAMPLE/"$SAMPLE".snf --threads $CPU --reference $GENOME --sample-id $SAMPLE --output-rnames --combine-consensus --allow-overwrite

# 2. Sort, remove SVs where END is < than POS (usually happens if a SV is at POS 1 on an uplaced contig) and remove unplaced contigs
bcftools view -R $CHR_BED $CALLS_DIR/sniffles/$SAMPLE/"$SAMPLE"_all_contigs.vcf.gz | bcftools filter -e "POS > INFO/END" > $CALLS_DIR/sniffles/$SAMPLE/"$SAMPLE".vcf

# 3. Filter for PASS and PRECISE calls and remove BNDs and INVDUPs
bcftools filter -i 'FILTER="PASS" & PRECISE=1 & SVTYPE!="BND" & SVTYPE!="INVDUP"' $CALLS_DIR/sniffles/$SAMPLE/"$SAMPLE".vcf > $CALLS_DIR/sniffles/"$SAMPLE"_PASS_PRECISE.vcf




