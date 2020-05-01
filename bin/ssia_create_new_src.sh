#!/bin/bash

rels=/home/ssia/shared/rels.tsv
queries=/home/ssia/shared/queries.txt
src_dir=/home/ssia/shared/src
tgt_dir=/home/ssia/shared

mkdir -p $tgt_dir/src_new || exit "Mkdir error"

## Create queries_new.txt
awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $rels $queries > $tgt_dir/queries_new.txt

## Create src_new directory
ls $src_dir/*.txt > $tgt_dir/src.list

# Select the files in src that are in rels.tsv file
awk 'NR==FNR{a[$2];next}{split($6,arr,"."); if (arr[1] in a) {print $0}}' \
	$rels FS="/" $tgt_dir/src.list > $tgt_dir/src_selected.list

# Create a command file. Note that the tgt_dir name needs to have same root
# dir as src_dir, and differs only at subdir name "src_new". Otherwise, you should change the
# pattern in gsub.
awk '{a=$0;gsub(/src/,"src_new", $0); print "cp "a" "$0}' $tgt_dir/src_selected.list > $tgt_dir/cp_src_selected.sh

# Copy the selected files to the new folder
bash $tgt_dir/cp_src_selected.sh

