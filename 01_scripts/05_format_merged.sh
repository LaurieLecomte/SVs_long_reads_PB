#!/bin/bash

# Format merged output to prepare for merging with SVs from short reads

# manitou
# srun -c 1 -p small --mem=200G -J 05_format_merged -o log/05_format_merged_%j.log /bin/sh 01_scripts/05_format_merged.sh &

# valeria
# srun -c 1 -p ibis_medium --time=2-00:00:00 --mem=200G -J 05_format_merged -o log/05_format_merged_%j.log /bin/sh 01_scripts/05_format_merged.sh &
 
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

#CPU=4


# LOAD REQUIRED MODULES
module load R/4.1
module load bcftools/1.13

# 1. Format header
## Extract lines for fields other than INFO, FORMAT and bcftools commands
bcftools view -h $MERGED_VCF | grep -E '=END,|=SVLEN|=SVTYPE|=SUPP,|=SUPP_VEC,|=GT,|ALT=<|FILTER=<|##file' | grep -E -v 'contig|bcftools|cmd' > $MERGED_UNION_DIR/VCF_lines.txt
## Contigs lines, excluding regions/contigs in $REGIONS_EX
bcftools view -h $MERGED_VCF | grep 'contig=' | grep -vFf $REGIONS_EX > $MERGED_UNION_DIR/VCF_chrs.txt

## Cat these together
cat $MERGED_UNION_DIR/VCF_lines.txt $MERGED_UNION_DIR/VCF_chrs.txt > $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".header

# 2. Format VCF : add explicit alternate sequence when possible
Rscript 01_scripts/format_merged_LR.R $MERGED_VCF $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".vcf.tmp $GENOME

# 3. Add header
cat $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".header $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".vcf.tmp > $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)"_formatted.vcf


# 4. Rename samples and sort 
bcftools query -l $MERGED_VCF > 02_infos/merged_sample_names.original

Rscript 01_scripts/utils/format_merged_sample_names.R 02_infos/merged_sample_names.original sniffles svim nanovar 02_infos/merged_sample_names.final
bcftools reheader -s 02_infos/merged_sample_names.final $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)"_formatted.vcf | bcftools sort > $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".sorted.vcf


# Clean up 
#rm $MERGED_UNION_DIR/VCF_lines.txt
#rm $MERGED_UNION_DIR/VCF_chrs.txt
#rm $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".header
#rm $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)".vcf.tmp
#rm $MERGED_UNION_DIR/"$(basename -s .vcf $MERGED_VCF)"_formatted.vcf
#rm 02_infos/merged_sample_names.original
#rm 02_infos/merged_sample_names.final