#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

# This Script prepares Trec Data before it can be used in Stage 1-5 of the Pipeline
# This is Stage 0: Getting/Preparing Data

sstage=0
estage=0
translate=1
reset=0 # copies all directories
merge=0
baseline=0

processd=()

TRECDIR_org=/home/hltcoe/kduh/data/ir/trec/
TRECDIR=/home/hltcoe/ssia/trec

DOCS=$TRECDIR
RELS=$TRECDIR/RELS
QUERIES=$TRECDIR/QUERIES
BITEXT=/home/hltcoe/ssia/parallel_corpora/split

declare -A L
declare -A L_org

L=(
#['arabic']=${DOCS}/English_data
['chinese']=${DOCS}/chinese
#['spanish']=${DOCS}/German_data
)

# removing and copy entire directories
if [ $reset -eq 1 ]; then
  [ -d $TRECDIR ] && rm -r $TRECDIR
  cp -r $TRECDIR_org $TRECDIR
  mkdir -p $QUERIES
fi


# Stage 0: Get Data
for lang in "${!L[@]}"; do
  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

    if [[ "${processd[@]}" =~ "query" ]]; then
      # process title and alltext for trecs56 and trec9
      # This constructs two versions of the query, one with title only 'query_title.txt', 
      # and the other with query, description, and narraive 'query_all.txt'
      if [[ $lang == "chinese" ]]; then
        rm_mk $QUERIES/QUERY_$lang
        cat ${L[$lang]}/trecs56/topics/all.topics.trec56.utf8 > $QUERIES/QUERY_$lang/all_topics.txt
        cat ${L[$lang]}/trec9/topics/xling9-topics.txt >> $QUERIES/QUERY_$lang/all_topics.txt
        python src/docparser.py query $QUERIES/QUERY_$lang/all_topics.txt $QUERIES/QUERY_$lang
      fi
    fi

    if [[ "${processd[@]}" =~ "rel" ]]; then

      mkdir -p $RELS
      echo "Processing rel files..."
      relf=$RELS/qrels_${lang}.txt

      [[ -f $relf ]] && rm $relf

      if [[ $lang == "chinese" ]]; then
        cat ${L[$lang]}/trec9/qrels/xling9_qrels > $relf
        cat ${L[$lang]}/trecs56/qrels/qrels_trec56 >> $relf
      fi

      # Keep only the rel mappings "1" in 4th column
      awk '{ if ($4==1) {print }}' $relf > $relf.temp

      # The queries from rel file are inconsistent with the query file names. query08 should be
      # query008. We need to reformat the double digit queries to three digits.
      awk '{ if (length($1)==1) {print "query00"$1" "$3} if (length($1)==2) {print "query0"$1" "$3} if (length($1)==3) {print "query"$1" "$3}}' $relf.temp > $relf
      rm $relf.temp
    fi
    
    if [[ "${processd[@]}" =~ "doc" ]]; then
      # extract untar documents
      #for subdir in `ls -I "*_txt*" ${L[$lang]}/trec{9,s56}/docs`; do
      #for subdir in `ls -I "*_txt*" ${L[$lang]}/trecs56/docs`; do

      for subdir in `ls -d ${L[$lang]}/trec{9,s56}/docs/* | grep -v '_txt'`; do
        #echo "Untaring $subdir"
        ls $subdir/*.gz | xargs -n1 -I % gunzip % 
        ls $subdir | grep -v "*.sgml" | xargs -n1 -I % mv % %.sgml
       
        #rm_mk ${subdir}_txt
        for fil in `ls $subdir/*.sgml`; do
          conv_encoding $fil
          python src/docparser.py doc $fil ${subdir}_txt
        done
      done
    fi
    # Translate Target Language (German, French, Russian) to English
      # For this we use pre-trained fairseq
      # Note this requires rtx gpus on COE-Grid
    if [[ $translate -eq 1 ]]; then
      for fild in `ls -d ${L[$lang]}/trec{9,s56}/docs/* | grep "_txt$"`; do
        rm_mk ${fild}_en.tmp
      #for $fild in `ls -d ${L[$lang]}/trec56s/docs/* | grep "_txt$"`; do
      #  mkdir -p ${fild}_en.tmp
        echo "Translating $lang.. $fild"
        python src/translate.py $lang $fild
      done
      #python src/translate.py $lang ${L[$lang]}/trecs56/docs/peoples-daily_txt
    fi
  fi
done

