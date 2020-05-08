#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

sstage=1
estage=1

processd=(doc rel)

DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04

DIR0003=/home/hltcoe/ssia/clef00-03
DIR0304=/home/hltcoe/ssia/clef03-04

DOCS=$DIR0003/DocumentData/DataCollections
DOCS_org=$DIR0003_org/DocumentData/DataCollections

RELS=$DIR0003/RelAssess
QUERIES=$DIR0003/Topics

declare -A L
declare -A L_org

L=(
#['english']=${DOCS}/English_data
#['french']=${DOCS}/French_data
#['german']=${DOCS}/German_data
['russian']=${DOCS}/Russian_data
#['spanish']=${DOCS}/Spanish_data
)

L_org=(
#['english']=${DOCS_org}/English_data
#['french']=${DOCS_org}/French_data
#['german']=${DOCS_org}/German_data
['russian']=${DOCS_org}/Russian_data
#['spanish']=${DOCS_org}/Spanish_data
)



# Stage 0: Get Data
if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

  # removing and copy entire directories
#  [ -d $DIR0003 ] && rm -r $DIR0003
#  [ -d $DIR0304 ] && rm -r $DIR0304

#  cp -r $DIR0003_org $DIR0003
#  cp -r $DIR0304_org $DIR0304
  if [[ "${processd[@]}" =~ "query" ]]; then
    [ -d $DIR0003/Topics ] && rm -r $DIR0003/Topics
    cp -r $DIR0003_org/Topics $DIR0003
    
    tfil=$DIR0003/Topics/topics2000
    mv $tfil/TOP-G.txt $tfil/Top-de00.txt
    mv $tfil/TOP-E.txt $tfil/Top-en00.txt
    mv $tfil/TOP-SP.txt $tfil/Top-es00.txt
    mv $tfil/TOP-FI.txt $tfil/Top-fi00.txt
    mv $tfil/TOP-D.txt $tfil/Top-nl00.txt
    mv $tfil/TOP-F.txt $tfil/Top-fr00.txt
    mv $tfil/TOP-I.txt $tfil/Top-it00.txt
    mv $tfil/TOP-SW.txt $tfil/Top-sw00.txt

  fi

  if [[ "${processd[@]}" =~ "rel" ]]; then
    [ -d $DIR0003/RelAssess ] && rm -r $DIR0003/RelAssess
    cp -r $DIR0003_org/RelAssess $DIR0003

    mv $RELS/2000rels/biling_qrels $RELS/2000rels/english_qrels
    mv $RELS/2001rels/qrels_bilingual $RELS/2001rels/qrels_english
  fi

fi

for lang in "${!L[@]}"; do

  # Stage 0: Get Data
  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

    if [[ "${processd[@]}" =~ "rel" ]]; then
      relf=$RELS/all_yrs/qrels_${lang}.txt
      [[ -f $relf ]] && rm $relf
      mkdir -p $RELS/all_yrs
    
      # bear with the ugliness cos formatting is messed up
      cat $RELS/2000rels/${lang}_qrels >> $relf
      cat $RELS/2001rels/qrels_${lang} >> $relf
      lang2=`conv_lang $lang`
      cat $RELS/2002rels/qrels_${lang2} >> $relf
      cat $RELS/2003rels/qrels_${lang2} >> $relf

      awk '{ if ($4==1) {print }}' $relf > $relf.temp
      awk '{ if (length($1)==2) {print "query0"$1" "$3} else {print "query"$1" "$3}}' $relf.temp > $relf
      rm $relf.temp
      # trec eval format
      awk '{print $1"\tQ0\t"$2"\t1"}' $relf > $relf.trec
    fi

    if [[ "${processd[@]}" =~ "doc" ]]; then
      rm -r ${L[$lang]}
      cp -r ${L_org[$lang]} $DOCS

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

      if [ "$lang" == "russian" ]; then
        rename '.xml' '.sgml' $DOCS/Russian_data/xml/*
        #ls $DOCS/Russian_data/xml/*.xml | xargs -n1 -I % mv % %.sgml
      fi

      # Extracting documents from sgml files
      for subdir in `ls -I 'valid_ids' -I 'README' -I '*.tgz' -I '*.dtd' -I '*_txt' ${L[$lang]}`; do
        rm_mk ${L[$lang]}/${subdir}_txt
        for fil in `ls ${L[$lang]}/${subdir}/*.sgml`; do
          # check if utf-8, else convert
          conv_encoding $fil
          # extract documents which are relevant, xclude if they dont exist in relfile 
          python src/docparser.py doc ${fil} ${L[$lang]}/${subdir}_txt $relfile
        done
      done

      # Copy all documents into specific all_docs folder
      rm_mk ${L[$lang]}/all_docs
      for subdir in `ls -d ${L[$lang]}/*_txt`; do
        cp $subdir/* ${L[$lang]}/all_docs
      done

      # Getting Valid Ids from extracted documents
      [ -f ${L[$lang]} ] && rm ${L[$lang]}/valid_ids 
      for subfil in `ls ${L[$lang]}/*_txt`; do
        echo "$subfil" >> ${L[$lang]}/valid_ids 
      done
      cat ${L[$lang]}/valid_ids | sort -u > ${L[$lang]}/valid_ids.tmp
      mv ${L[$lang]}/valid_ids.tmp ${L[$lang]}/valid_ids
    fi # end process doc

    # Deprecated
    #if [[ "${processd[@]}" =~ "mapping" ]]; then
    #  savefn=$RELS/all_yrs/qrels_en-$lang.txt
    #  python src/merge_clef_relfiles.py $lang $savefn
    #fi

    if [[ "${processd[@]}" =~ "query" ]]; then
      rm_mk $QUERIES/QUERY_${lang}
      for yr in 00 01 02 03; do #2000 is broken
        langt=`conv_lang $lang lower`
        fil=$QUERIES/topics20${yr}/Top-${langt}${yr}.txt
        conv_encoding $fil

      #  extract query from sgml file into single line, same as MATERIAL
        python src/docparser.py query $fil $QUERIES/QUERY_${lang} $yr
      done
      
      cat $QUERIES/QUERY_${lang}/query{00,01,02,03}.txt > $QUERIES/QUERY_${lang}/query.txt
    fi
  fi # end stage 0

  ####### STAGE 1
  # this script is from print_utils.sh

  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics:\n"

    if [[ "${processd[@]}" =~ "doc" ]]; then
      doc_stats ${L[$lang]}/all_docs
    fi

    if [[ "${processd[@]}" =~ "query" ]]; then
      print_query $QUERIES/QUERY_${lang}/query.txt
    fi

    if [[ "${processd[@]}" =~ "rel" ]]; then
      print_mapping $RELS/all_yrs/qrels_$lang.txt
    fi
    
  fi
#  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
#  fi
#  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
#  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
#  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
#  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then



done # iterate languages
