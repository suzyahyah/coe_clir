#!/usr/bin/env bash
# Author: Suzanna Sia

# 1. Copy from Kevin's dir
sstage=0
estage=0

processd=(doc)

DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04

#DIR0003=/home/hltcoe/ssia/clef00-03
#DIR0304=/home/hltcoe/ssia/clef03-04
DIR0003=/export/c12/ssia/data/clef00-03
DIR0304=/export/c12/ssia/data/clef03-04

DOCS=$DIR0003/DocumentData/DataCollections
RELS=$DIR0003/RelAssess

declare -A L

L=(
#['english']=${DOCS}/English_data
['french']=${DOCS}/French_data
#['german']=${DOCS}/German_data
#['russian']=${DOCS}/Russian_data
['spanish']=${DOCS}/Spanish_data
)

conv_lang() {
  [[ "$1" == "english" ]] && lang="EN";
  [[ "$1" == "spanish" ]] && lang="ES";
  [[ "$1" == "german" ]] && lang="DE";
  [[ "$1" == "french" ]] && lang="FR";
  [[ "$1" == "finnish" ]] && lang="FI";
  [[ "$1" == "italian" ]] && lang="IT";
  [[ "$1" == "russian" ]] && lang="RU";
  [[ "$1" == "swedish" ]] && lang="SV";
  echo "$lang"
}



rm_mk(){
  [ -d $1 ] && rm -r $1
  mkdir -p $1
}

# Stage 0: Get Data
if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  # removing and copying directories
  [ -d $DIR0003 ] && rm -r $DIR0003
  [ -d $DIR0304 ] && rm -r $DIR0304

  cp -r $DIR0003_org $DIR0003
  cp -r $DIR0304_org $DIR0304

fi

for lang in "${!L[@]}"; do

  # Stage 0: Get Data
  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

    if [[ "${processd[@]}" =~ "rel" ]]; then
      rm $RELS/all_yrs/qrels_${lang}.txt

      if [ "$lang" == "english" ]; then
        cat $RELS/2000rels/biling_qrels > $RELS/all_yrs/qrels_english.txt
        cat $RELS/2001rels/qrels_bilingual > $RELS/all_yrs/qrels_english.txt
        cat $RELS/2002rels/qrels_EN > $RELS/all_yrs/qrels_english.txt
        cat $RELS/2003rels/qrels_EN > $RELS/all_yrs/qrels_english.txt
      else 
        echo $lang
        cat $RELS/2000rels/${lang}_qrels >> $RELS/all_yrs/qrels_${lang}.txt
        cat $RELS/2001rels/qrels_${lang} >> $RELS/all_yrs/qrels_${lang}.txt
        lang2=`conv_lang $lang`
        cat $RELS/2002rels/qrels_${lang2} >> $RELS/all_yrs/qrels_${lang}.txt
        cat $RELS/2003rels/qrels_${lang2} >> $RELS/all_yrs/qrels_${lang}.txt
        
      fi

      awk '{ if ($4==1) {print }}' $RELS/all_yrs/qrels_${lang}.txt \
      > $RELS/all_yrs/qrels_${lang}.txt.temp 
      mv $RELS/all_yrs/qrels_${lang}.txt.temp $RELS/all_yrs/qrels_${lang}.txt
    fi

    # test this function tomorrow
    if [[ "${processd[@]}" =~ "doc" ]]; then

      relfile=$RELS/all_yrs/qrels_${lang}.txt

      # Untar all the files 
      for subdir in `ls -d ${L[$lang]}`; do
        printf "Untaring $subdir"
        ls $subdir/*.tgz | xargs -n1 -I % tar -xzf % -C $subdir
      done

      if [ "$lang" == "english" ]; then
        mkdir -p $DOCS/English_data/la
        mv $DOCS/English_data/la*.gz $DOCS/English_data/la
        gunzip $DOCS/English_data/la/*.gz
      fi

      if [ "$lang" == "french" ]; then
        ls -I "*.sgml" $DOCS/french_data/new_docno/*  | xargs -n1 -I % mv % %.sgml
        mv $DOCS/french_data/new_docno/lemonde.dtd.sgml $DOCS/french_data/new_docno/lemonde.dtd
      fi

      # Convert to UTF-8
      for subdir in `ls -I '*.tgz' -I '*.dtd' -I '*_txt' ${L[$lang]}`; do

        rm_mk ${L[$lang]}/${subdir}_txt
        for fil in `ls ${L[$lang]}/${subdir}/*.sgml`; do
        
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
          
          # extract documents which are relevant
          python src/docparser.py ${fil} ${L[$lang]}/${subdir}_txt $relfile
          
        done
      done
    fi # end process doc
  fi # end stage 0


  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics:\n"

    #if [[ "${processd[@]}" =~ "query" ]]; then

    #fi
    
  fi
#  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
#  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
#  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
#  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
#  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then



done # iterate languages
