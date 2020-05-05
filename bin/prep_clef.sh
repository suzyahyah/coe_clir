#!/usr/bin/env bash
# Author: Suzanna Sia

DIR0003=/export/c12/ssia/data/clef00-03
DIR0304=/export/c12/ssia/data/clef03-04

#for DIR in `ls -d $DIR0003/DocumentData/DataCollections/*_data`; do
  #printf "Untaring $DIR"
  #tar -xzf $DIR/*.tgz -C $DIR
#  ls $DIR/*.tgz | xargs -p -n1 -I % tar -xzf % -C $DIR
#done

# mkdir for text files

for DIR in `ls -d $DIR0003/DocumentData/DataCollections/*_data`; do
  echo $DIR
  for SUBDIR in  `ls -I '*.tgz' -I '*.dtd' -I '*_txt' $DIR`; do
    echo $SUBDIR
    mkdir -p $DIR/${SUBDIR}_txt
    for fil in `ls $DIR/$SUBDIR/*.sgml`; do
      python src/docparser.py $fil $DIR/${SUBDIR}_txt
    done
  done
done



# for english do
#mkdir -p la
#mv la*.gz la
#gunzip la/*.gz .

