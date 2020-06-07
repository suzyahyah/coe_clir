#!/usr/bin/env bash
# Author: Suzanna Sia

DIR0003=/home/hltcoe/ssia/clef00-03
DOCS=$DIR0003/DocumentData/DataCollections
RELS=$DIR0003/RelAssess

declare -A L
declare -A L_org

L=(
#['amaryllis']=${DOCS}/Amaryllis_data
['dutch']=${DOCS}/Dutch_data
['english']=${DOCS}/English_data
['finnish']=${DOCS}/Finnish_data
['french']=${DOCS}/French_data
['german']=${DOCS}/German_data
['italian']=${DOCS}/Italian_data
['russian']=${DOCS}/Russian_data
['spanish']=${DOCS}/Spanish_data
['swedish']=${DOCS}/Swedish_data
)


# total docs in directory
total_doc_counts(){
  ldir=${L[$1]}
  docs=`ls $ldir/*_txt/* | wc -l`
  echo $docs in $1
}


total=0
for lang in "${!L[@]}"; do
  #total_doc_counts $lang
  #nqueries=`cat QUERY_${lang}/query_title.txt | wc -l`
  #printf "\nNo. $lang queries: $nqueries\n"
  for year in 2000 2001 2002 2003; do
    nrel=`ls $RELS/qrels_$lang/$year.txt | xargs -n 1 wc -l | awk '{print $1}'`


    [[ $year -eq 2000 ]] && val=$(($nrel * 8)) 
    [[ $year -eq 2001 ]] && val=$(($nrel * 11)) 
    [[ $year -eq 2002 ]] && val=$(($nrel * 12)) 
    [[ $year -eq 2003 ]] && val=$(($nrel * 12))  

    echo -e "$lang $year rels:$nrel rels_times_nlangs: $val" && total=$(($total+$val))
  done
done
echo "Total: $total"
