#!/bin/bash 

# Test svision using mapped reads from winnowmap

# 0. git clone https://github.com/xjtu-omics/SVision.git
#    cd SVisio
# 1. Install required packages in a conda env from modified .yml file environment_custom.yml: conda env create -f environment_custom.yml -> I added explicit version num for opencv-python-headless
# 2. python setup.py install



# parallel -a 02_infos/ind_PB.txt -j 2 srun -p medium -c 10 --time=7-00:00 --mem=50G -J SVision_call_winnow_{} --mem=20G -o log/SVision_call_winnow_{}_%j.log /bin/sh 01_scripts/SVision_call_winnow.sh {} &

# srun -p small -c 10 --time=1-00:00 -J SVision_call_winnow_safoPUVx_001-21 --mem=50G -o log/SVision_call_winnow_safoPUVx_001-21_%j.log /bin/sh 01_scripts/svision_call_winnow.sh safoPUVx_001-21 &


# VARIABLES
SAMPLE=$1

GENOME="03_genome/genome.fasta"
CHR_BED="02_infos/chrs.bed.gz"
BAM_DIR="04_bam"
CALLS_DIR="05_calls/SVision"
MERGED_DIR="06_merged/SVision"
FILT_DIR="07_filtered/SVision"

CPU=10

MODEL="$CALLS_DIR/model/svision-cnn-model.ckpt"

MIN_READ=2

CHR_LIST="02_infos/chr_list.txt"


# 0. Create output dir
if [[ ! -d "$CALLS_DIR/$SAMPLE" ]]
then
  mkdir "$CALLS_DIR/$SAMPLE"
fi


# Call 
zless $CHR_LIST | while read CHR;
do
  # Call SVs in each chromosome
  SVision -o $CALLS_DIR/$SAMPLE/"$CHR_" -b $BAM_DIR/"$SAMPLE".ccs.bam -m $MODEL -g $GENOME -n $SAMPLE -s $MIN_READ --graph --qname --max_sv_size 10000000 -t $CPU -c $CHR;
done


# Concat all files together

#cat $CALLS_DIR/$SAMPLE/^CM*.vcf > $CALLS_DIR/$SAMPLE/"$SAMPLE"_chrs.vcf