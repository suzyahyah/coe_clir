#!/bin/bash
# Author: Yang Jinyi; Suzanna Sia

dir=/export/fs04/a05/kduh/share
tgt_dir=/home/ssia/projects/coe_clir/data/mt2

del_mk_cp(){
  
  tgtdir=/home/ssia/projects/coe_clir/data/DOCS_$2/ANALYSIS/mt2_eng.tmp
  echo $tgtdir
  echo $2
  [ -d $tgtdir ] && rm -r $tgtdir
  mkdir -p $tgtdir

  if [ "$2" == "SOMA" ]; then
    cp $1/so-en.ANALYSIS{1,2}/* $tgtdir
  elif [ "$2" == "TAGA" ]; then
    cp $1/tl-en.ANALYSIS{1,2}/* $tgtdir
  elif [ "$2" == "SWAH" ]; then
    cp $1/sw-en.ANALYSIS{1,2}/* $tgtdir
  fi

}

if [ $1 == "SOMA" ]; then
  docid_files=`ls $dir/so-*.docid`

elif [ $1 == "TAGA" ]; then
  docid_files=`ls $dir/tl-*.docid`

elif [ $1 == "SWAH" ]; then
  docid_files=`ls $dir/sw-*.docid`
fi

echo $docid_files

#docid_files=`ls $dir/*.docid`

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

del_mk_cp $tgt_dir $1
