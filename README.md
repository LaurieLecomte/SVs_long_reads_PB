# SV calling pipeline from long read sequencing data

## TO DO
* Load required modules outside of scripts and correct versions for both manitou and valeria 

## Pipeline Overview

1. **Call SVs** : the 3 tools may be used independently in any order or at the same time.
* 1.1. Sniffles : scripts `01.1` to `01.4`
* 2.2. SVIM : scripts `02.1` to `02.4`

4. **Merge SV calls** across callers : `04_merge_callers.sh`
5. Format merged output : `05_format_merged.sh`
6. **Filter** merged output : `06_filter_merged.sh` 


### Additional scripts

Other scripts targeting a specific step or operation conducted in one of the main scripts or allowing additional analyses are provided in the `01_scripts/utils` subdirectory.

* `01_scripts/utils/format_add_ALTseq_LR.R` : adds an explicit alternate sequence (when possible) to the merged SVs. Called by the `01_scripts/utils/format_merged.R` script featured in the `05_format_merged.sh` main script.
* `01_scripts/utils/format_merged_sample_names.R` : add unique sample names to the merged VCF, also called by the `05_format_merged.sh` main script.
* `01_scripts/utils/combined_plot_by_caller.R` : used for plotting filtered short-read SVs, called by the `01_scripts/utils/summarize_plot.sh` script (Supp. Fig. 4 from the paper [Investigating structural variant, indel and single nucleotide polymorphism differentiation between locally adapted Atlantic salmon populations using whole genome sequencing and a hybrid genomic polymorphism detection approach](https://www.biorxiv.org/content/10.1101/2023.09.12.557169v1))

Older scripts used for development or debugging purposes are stored in the `01_scripts/archive` folder for future reference if needed. These are not meant to be used in their current state and may be obsolete.

## Prerequisites

### Files

* A reference genome named `genome.fasta` and its index (.fai) in `03_genome`
* Bam files for all samples and their index. These can be soft-linked in the 04_bam folder for easier handling : if `$BAM_PATH` is the remote path to bam files, use `for file in $(ls -1 $BAM_PATH/*); do ln -s $file ./04_bam; done`. These should be named as `SAMPLEID.bam` (see sample ID list below).
* A bam files list in `02_infos`. This list can be generated with the following command, where `$BAM_DIR` is the path of the directory where bam files are located : `ls -1 $BAM_DIR/*.bam > 02_infos/bam_list.txt`
* A chromosomes list (or contigs, or sites) in `02_infos`. This list is used for parallelizing the SV calling step. It can be produced from the indexed genome file (`"$GENOME".fai`) : `less "$GENOME".fai | cut -f1 > 02_infos/chr_list.txt`
* If some chromosomes are to be excluded from the SV calling step, such as unplaced contigs, these must be listed in `02_infos/excl_chrs.txt`, which needs to be encoded in linux format AND have a newline at the end.
* A chromosomes list in the form of a bed file (`02_infos/chrs.bed`). We use the one produced by `00_prepare_regions.sh` from the [SVs_SR_pipeline](https://github.com/LaurieLecomte/SVs_short_reads/blob/main/01_scripts/00_prepare_regions.sh)
* A sample IDs list (`02_infos/ind_ALL.txt`), one ID per line. This list can be used for renaming bam files symlinks in `$BAM_DIR`, adjust `grep` command as required (warning : use carefully): `less 02_infos/ind_ALL.txt | while read ID; do BAM_NAME=$(ls $BAM_DIR/*.bam | grep "$ID"); mv $BAM_NAME $BAM_DIR/"$ID".bam; done` and `less 02_infos/ind_ALL.txt | while read ID; do BAM_NAME=$(ls $BAM_DIR/*.bai | grep "$ID"); mv $BAM_NAME $BAM_DIR/"$ID".bam.bai; done`


### Software

#### For Manitou and Valeria users


## Detailed Walkthrough

### Sniffles

#### `01.1_sniffles_call.sh`

Call SVs in all samples and remove unplaced contigs

* On manitou : `parallel -a 02_infos/ind_ALL.txt -k -j 10 srun -c 1 --mem=20G -p medium --time=7-00:00 -J 01.1_sniffles_call_{} -o log/01.1_sniffles_call_{}_%j.log 01_scripts/01.1_sniffles_call.sh {} &`
* On valeria : `parallel -a 02_infos/ind_ALL.txt -k -j 10 srun -c 1 --mem=20G -p ibis_medium --time=7-00:00 -J 01.1_sniffles_call_{} -o log/01.1_sniffles_call_{}_%j.log 01_scripts/01.1_sniffles_call.sh {} &`

#### `01.2_sniffles_refine.sh`

Run Iris to refine SV sequences.

* On manitou : `parallel -a 02_infos/ind_ONT.txt -j 4 srun -c 10 -p medium --time=3-00:00:00 -J 01.2_sniffles_refine_{} --mem=80G -o log/01.2_sniffles_refine_{}_%j.log /bin/sh ./01_scripts/01.2_sniffles_refine.sh {} &`

* On valeria : `parallel -a 02_infos/ind_ONT.txt -j 4 srun -c 10 -p ibis_medium --time=7-00:00:00 -J 01.2_sniffles_refine_{} --mem=100G -o log/01.2_sniffles_refine_{}_%j.log /bin/sh ./01_scripts/01.2_sniffles_refine.sh {} &`


#### `01.3_sniffles_merge.sh`

 Merge refined Sniffles SVs across samples with Jasmine

* On manitou : `srun -c 8 -p medium --time=2-00:00:00 -J 01.3_sniffles_merge --mem=100G -o log/01.3_sniffles_merge_%j.log /bin/sh ./01_scripts/01.3_sniffles_merge.sh &`

* On valeria : `srun -c 8 -p ibis_medium --time=2-00:00:00 -J 01.3_sniffles_merge --mem=100G -o log/01.3_sniffles_merge_%j.log /bin/sh ./01_scripts/01.3_sniffles_merge.sh &`


#### `01.4_sniffles_filter_format.sh`

Re-filter SVs called by Sniffles and format the multisample VCF

* On manitou : `srun -c 1 -p small --time=1-00:00:00 -J 01.4_sniffles_filter_format --mem=20G -o log/01.4_sniffles_filter_format_%j.log /bin/sh ./01_scripts/01.4_sniffles_filter_format.sh &`

* On valeria : `srun -c 1 -p ibis_small --time=1-00:00:00 -J 01.4_sniffles_filter_format --mem=20G -o log/01.4_sniffles_filter_format_%j.log /bin/sh ./01_scripts/01.4_sniffles_filter_format.sh &`




### SVIM

In parallel commands, replace the `-j 4` argument by the required number of samples.

#### `01.1_svim_call.sh`

Call SVs with SVIM2 across whole genome, including unplaced contigs, which will be removed after

* On valeria : svim cannot read sample names from -a arg of parallel.. no idea why
* On manitou : `parallel -a 02_infos/ind_ONT.txt -j 4 srun -c 1 -p ibis_small --mem=20G --time=1-00:00:00 -J 02.1_svim_call_{} -o log/02.1_svim_call_{}_%j.log /bin/sh ./01_scripts/02.1_svim_call.sh {} &`


#### `01.2_svim_refine.sh`

Run Iris to refine SV sequences.

* On manitou : `parallel -a 02_infos/ind_ONT.txt -j 4 srun -c 10 -p medium --time=3-00:00:00 -J 01.2_svim_refine_{} --mem=80G -o log/01.2_svim_refine_{}_%j.log /bin/sh ./01_scripts/01.2_svim_refine.sh {} &`

* On valeria : `parallel -a 02_infos/ind_ONT.txt -j 4 srun -c 10 -p ibis_medium --time=7-00:00:00 -J 01.2_svim_refine_{} --mem=100G -o log/01.2_svim_refine_{}_%j.log /bin/sh ./01_scripts/01.2_svim_refine.sh {} &`


#### `01.3_svim_merge.sh`

 Merge refined svim SVs across samples with Jasmine

* On manitou : `srun -c 8 -p medium --time=2-00:00:00 -J 01.3_svim_merge --mem=100G -o log/01.3_svim_merge_%j.log /bin/sh ./01_scripts/01.3_svim_merge.sh &`

* On valeria : `srun -c 8 -p ibis_medium --time=2-00:00:00 -J 01.3_svim_merge --mem=100G -o log/01.3_svim_merge_%j.log /bin/sh ./01_scripts/01.3_svim_merge.sh &`


#### `01.4_svim_filter_format.sh`

Re-filter SVs called by svim and format the multisample VCF

* On manitou : `srun -c 1 -p small --time=1-00:00:00 -J 01.4_svim_filter_format --mem=20G -o log/01.4_svim_filter_format_%j.log /bin/sh ./01_scripts/01.4_svim_filter_format.sh &`

* On valeria : `srun -c 1 -p ibis_small --time=1-00:00:00 -J 01.4_svim_filter_format --mem=20G -o log/01.4_svim_filter_format_%j.log /bin/sh ./01_scripts/01.4_svim_filter_format.sh &`





### `04_merge_callers.sh`

### `05_format_merged.sh`

### `06_filter_merged.sh`


