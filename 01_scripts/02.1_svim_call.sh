#!/bin/bash

# Call SVs with svim2 across whole genome, including unplaced contigs which will be removed after

# valeria : svim cannot read sample names from -a arg of parallel.. no idea why, investigate with 1KB log files named 02.1_svim_call_{}_%j.log
# parallel -a 02_infos/ind_PB.txt -j 4 srun -c 1 -p small --mem=20G --time=1-00:00:00 -J 02.1_svim_call_{} -o log/02.1_svim_call_{}_%j.log /bin/sh ./01_scripts/02.1_svim_call.sh {} &

# VARIABLES
SAMPLE=$1

GENOME="03_genome/genome.fasta"
CHR_BED="02_infos/chrs.bed.gz"
BAM_DIR="04_bam"
CALLS_DIR="05_calls"
MERGED_DIR="06_merged"
FILT_DIR="07_filtered"

BAM="$BAM_DIR/"$SAMPLE".ccs.bam"

MIN_DEPTH=2 ## lower for ccs because similar subreads reads were collapsed into a consensus sequence

CPU=1

# 0. Create output dir
if [[ ! -d "$CALLS_DIR/svim/$SAMPLE" ]]
then
  mkdir "$CALLS_DIR/svim/$SAMPLE"
fi

# 1. Call SVs in whole genome

svim alignment $CALLS_DIR/svim/$SAMPLE $BAM $GENOME --insertion_sequences --read_names --sample $SAMPLE --max_consensus_length=500000 --interspersed_duplications_as_insertions --minimum_depth $MIN_DEPTH

# 2. Sort, remove SVs where END is < than POS (usually happens if a SV is at POS 1 on an uplaced contig), then compress and index
bcftools sort $CALLS_DIR/svim/$SAMPLE/variants.vcf | bcftools filter -e "POS > INFO/END" > $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_all_contigs.vcf
bgzip $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_all_contigs.vcf -f
tabix -p vcf $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_all_contigs.vcf.gz -f

# 3. Filter out unplaced contigs
bcftools view -R $CHR_BED $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_all_contigs.vcf.gz > $CALLS_DIR/svim/$SAMPLE/"$SAMPLE".vcf

# 4. Filter for PASS and PRECISE calls, remove BNDs
bcftools filter -i 'FILTER="PASS" & SVTYPE!="BND"' $CALLS_DIR/svim/$SAMPLE/"$SAMPLE".vcf > $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_PASS.vcf

# 5. Replace tag 'READS' by 'RNAMES' in header and in VCF fields
sed -E 's/ID\=READS\,/ID\=RNAMES\,/' $CALLS_DIR/svim/$SAMPLE/"$SAMPLE"_PASS.vcf | sed -E 's/;READS=/;RNAMES=/' > $CALLS_DIR/svim/"$SAMPLE"_PASS.vcf

