#!/usr/bin/env bash
# Author: Yang Jinyi, Suzanna Sia

printf "find match for $2 in $4\n"

cdir=$1
tmp=$cdir/$2
fol=$cdir/$3
relevfil=$4

rm_mk(){
  [ -d $1 ] && rm -r $1
  mkdir -p $1
}

rm_mk $fol

ls $tmp/*.txt > $cdir/src.list

awk 'NR==FNR{a[$2];next}{split($10,arr,"."); if (arr[1] in a) {print $0}}' \
  $relevfil FS="/" $cdir/src.list > $cdir/src_selected.list

if [ "$2" == "translation.tmp" ]; then
  awk '{a=$0;gsub(/translation.tmp/,"translation", $0); print "cp "a" "$0}' $cdir/src_selected.list > $cdir/cp_src_selected.sh
fi

if [ "$2" == "mt1_eng.tmp" ]; then
  awk '{a=$0;gsub(/mt1_eng.tmp/,"mt1_eng", $0); print "cp "a" "$0}' $cdir/src_selected.list > $cdir/cp_src_selected.sh
fi

if [ "$2" == "mt2_eng.tmp" ]; then
  echo "mt2 found"
  awk '{a=$0;gsub(/mt2_eng.tmp/,"mt2_eng", $0); print "cp "a" "$0}' $cdir/src_selected.list > $cdir/cp_src_selected.sh
fi

bash $cdir/cp_src_selected.sh

#clean up
rm $cdir/cp_src_selected.sh 
rm $cdir/src.list
rm $cdir/src_selected.list
rm -r $tmp
