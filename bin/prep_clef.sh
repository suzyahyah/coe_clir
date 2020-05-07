#!/usr/bin/env bash
# Author: Suzanna Sia

# 1. Copy from Kevin's dir
sstage=1
estage=1

processd=(mapping)

DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04

DIR0003=/home/hltcoe/ssia/clef00-03
DIR0304=/home/hltcoe/ssia/clef03-04
#DIR0003=/export/c12/ssia/data/clef00-03
#DIR0304=/export/c12/ssia/data/clef03-04

DOCS=$DIR0003/DocumentData/DataCollections
RELS=$DIR0003/RelAssess

declare -A L

L=(
#['english']=${DOCS}/English_data
#['french']=${DOCS}/French_data
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
#if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  # removing and copying directories
#  [ -d $DIR0003 ] && rm -r $DIR0003
#  [ -d $DIR0304 ] && rm -r $DIR0304

#  cp -r $DIR0003_org $DIR0003
#  cp -r $DIR0304_org $DIR0304

#fi

for lang in "${!L[@]}"; do

  # Stage 0: Get Data
  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

    if [[ "${processd[@]}" =~ "rel" ]]; then
      rm $RELS/all_yrs/qrels_${lang}.txt
      mkdir -p $RELS/all_yrs

      if [ "$lang" == "english" ]; then
        cat $RELS/2000rels/biling_qrels >> $RELS/all_yrs/qrels_english.txt
        cat $RELS/2001rels/qrels_bilingual >> $RELS/all_yrs/qrels_english.txt
        cat $RELS/2002rels/qrels_EN >> $RELS/all_yrs/qrels_english.txt
        cat $RELS/2003rels/qrels_EN >> $RELS/all_yrs/qrels_english.txt
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
        ls -I "*.sgml" $DOCS/English_data/la/*  | xargs -n1 -I % mv % %.sgml
      fi

      if [ "$lang" == "french" ]; then
        ls -I "*.sgml" $DOCS/French_data/new_docno/*  | xargs -n1 -I % mv % %.sgml
        mv $DOCS/French_data/new_docno/lemonde.dtd.sgml $DOCS/French_data/new_docno/lemonde.dtd
      fi

      # Extracting documents from sgml files
      for subdir in `ls -I 'valid_ids' -I 'README' -I '*.tgz' -I '*.dtd' -I '*_txt' ${L[$lang]}`; do
        rm_mk ${L[$lang]}/${subdir}_txt
        for fil in `ls ${L[$lang]}/${subdir}/*.sgml`; do
        
          # check if utf-8, else convert
          encoding=`file -b --mime-encoding $fil`
          echo "$encoding > utf-8 $fil"

          if [[ $encoding != "UTF-8" ]]; then
            if [[ $encoding == "us-ascii" ]]; then
              encoding="US-ASCII"
            fi
            iconv -f ${encoding} -t UTF-8 $fil > ${fil}.t
            mv ${fil}.t $fil
          fi
          # extract documents which are relevant
          python src/docparser.py ${fil} ${L[$lang]}/${subdir}_txt $relfile
        done
      done

      # Getting Valid Ids from extracted documents
      [ -f ${L[$lang]} ] && rm ${L[$lang]}/valid_ids 
      for subfil in `ls ${L[$lang]}/*_txt`; do
        echo "$subfil" >> ${L[$lang]}/valid_ids 
      done
      cat ${L[$lang]}/valid_ids | sort -u > ${L[$lang]}/valid_ids.tmp
      mv ${L[$lang]}/valid_ids.tmp ${L[$lang]}/valid_ids
    fi # end process doc

    if [[ "${processd[@]}" =~ "mapping" ]]; then
      savefn=$RELS/all_yrs/qrels_en-$lang.txt
      python src/merge_clef_relfiles.py $lang $savefn
    fi


  fi # end stage 0

  ####### STAGE 1

  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics:\n"

    #if [[ "${processd[@]}" =~ "doc" ]]; then
      # TODO
      # print the directory
      # num docs
      # avg nwords per doc
    #fi

    if [[ "${processd[@]}" =~ "mapping" ]]; then

      # this script mirrors run_all.sh

      if [[ "$lang" != "english" ]]; then

        printf "\n=== mapping ===\n"
        v1=$(wc -l $RELS/all_yrs/qrels_en-$lang.txt | awk '{print $1}')

        numq=$(awk '{print $1}' $RELS/all_yrs/qrels_en-$lang.txt | sort -u | wc -l)
        numd=$(awk '{print $2}' $RELS/all_yrs/qrels_en-$lang.txt | sort -u | wc -l)

        v3=$(awk "BEGIN{print $v1/$numq}")
        v4=$(awk "BEGIN{print $v1/$numd}")

        printf "\tnum of unique english docs: $numq\n"
        printf "\tnum of unique $lang docs: $numd\n"

        printf "\tavg num of $lang docs to english docs: $v3\n"
        printf "\tavg num of english docs to $lang doc: $v4\n"

        # trec eval format
        awk '{print $1"\tQ0\t"$2"\t1"}' $RELS/all_yrs/qrels_en-$lang.txt \
        > $RELS/all_yrs/qrels_en-$lang.txt.trec
      fi
    fi
    
  fi
#  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
#  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
#  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
#  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
#  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then



done # iterate languages
