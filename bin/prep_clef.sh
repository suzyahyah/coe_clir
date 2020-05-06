#!/usr/bin/env bash
# Author: Suzanna Sia

# 1. Copy from Kevin's dir

DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04
DIR0003=/home/hltcoe/ssia/clef00-03
DIR0304=/home/hltcoe/ssia/clef03-04

# removing and copying directories
[ -d $DIR0003 ] && rm -r $DIR0003
[ -d $DIR0304 ] && rm -r $DIR0304

cp -r $DIR0003_org $DIR0003
cp -r $DIR0304_org $DIR0304


for DIR in `ls -d $DIR0003/DocumentData/DataCollections/*_data`; do
  printf "Untaring $DIR"
#  tar -xzf $DIR/*.tgz -C $DIR
  ls $DIR/*.tgz | xargs -n1 -I % tar -xzf % -C $DIR

done
mkdir -p $DIR0003/DocumentData/DataCollections/English_data/la
mv $DIR0003/DocumentData/DataCollections/English_data/la*.gz $DIR0003/DocumentData/DataCollections/English_data/la
gunzip la/*.gz

# mkdir for text files

# Deal w relevance files
# fix odd renaming

mkdir -p $RelDir/all_yrs

#for fil in `ls -d $DIR0003/DocumentData/DataCollections/*_data`; do

cat $RelDir/2000rels/biling_qrels >> $RelDir/all_yrs/qrels_english-la
cat $RelDir/2000rels/french_qrels >> $RelDir/all_yrs/qrels_french
cat $RelDir/2000rels/german_qrels >> $RelDir/all_yrs/qrels_german
cat $RelDir/2000rels/girt_qrels >> $RelDir/all_yrs/qrels_girt
cat $RelDir/2000rels/italian_qrels >> $RelDir/all_yrs/qrels_italian
cat $RelDir/2000rels/multi_qrels >> $RelDir/all_yrs/qrels_multi


cat $RelDir/2001rels/qrels_bilingual >> $RelDir/all_yrs/qrels_english-la
cat $RelDir/2000rels/qrels_french >> $RelDir/all_yrs/qrels_french



for fil in `ls $RelDir/2000rels/*`; do
  #fil=`basename $fil`
  #lang=`echo $fil | awk -F'_' '{print tolower($1)}'`
  cat $fil >> 
  
done

for DIR in `ls -d $DIR0003/DocumentData/DataCollections/*_data`; do
  echo $DIR
  for SUBDIR in  `ls -I '*.tgz' -I '*.dtd' -I '*_txt' $DIR`; do
    echo $SUBDIR
    lang_dir=`basename $DIR`

    mkdir -p $DIR/${SUBDIR}_txt
    for fil in `ls $DIR/$SUBDIR/*.sgml`; do
    
      # check if utf-8, else convert
      encoding=`file $fil | awk '{print $4}'`
      echo "$encoding > utf-8 $fil"

      if [[ $encoding != "UTF-8" ]]; then
        if [[ $encoding == "ISO-8859" ]]; then
          encoding="${encoding}-1"
        fi
        iconv -f ${encoding} -t UTF-8 $fil > ${fil}.t
        mv ${fil}.t $fil
      fi
      python src/docparser.py ${fil} $DIR/${SUBDIR}_txt
      
    done
  done
done
