#!/bin/bash
# Author: Yang Jinyi; Suzanna Sia

dir=/export/fs04/a05/kduh/share
tgt_dir=/home/ssia/projects/coe_clir/temp/mt2

docid_files=`ls $dir/*.docid`

for d in ${docid_files}; do
	docname=`basename $d ".docid"`
	txtname=`echo $docname | sed 's/-text//'`
  subdir=$tgt_dir/$txtname
  echo "Creating $subdir"
  [ -d $subdir ] && rm -r $subdir
  mkdir -p $subdir || exit "Error mkdir"
	txtfile=$dir/${txtname}.nmt.en
  awk 'NR==FNR{arr[NR]=$1}(NR != FNR && arr[FNR]){print  >> (t"/"arr[FNR]".txt")}' \
    t="$subdir" $d $txtfile
done

mkdir -p $tgt_dir/../DOCS_SOMA/ANALYSIS/mt2_eng
mkdir -p $tgt_dir/../DOCS_SWAH/ANALYSIS/mt2_eng
mkdir -p $tgt_dir/../DOCS_TAGA/ANALYSIS/mt2_eng

cp $tgt_dir/so-en.ANALYSIS{1,2}/* $tgt_dir/../DOCS_SOMA/ANALYSIS/mt2_eng
cp $tgt_dir/sw-en.ANALYSIS{1,2}/* $tgt_dir/../DOCS_SWAH/ANALYSIS/mt2_eng
cp $tgt_dir/tl-en.ANALYSIS{1,2}/* $tgt_dir/../DOCS_TAGA/ANALYSIS/mt2_eng

