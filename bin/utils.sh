#!/usr/bin/env bash
# Author: Suzanna Sia

function rm_mk(){
  [ -d $1 ] && rm -r $1
   mkdir -p $1
}


function print_rel(){
  printf "\n=== rel ===\n"
  mapf=$1

  v1=$(wc -l $mapf | awk '{print $1}')

  numq=$(awk '{print $1}' $mapf | sort -u | wc -l)
  numd=$(awk '{print $2}' $mapf | sort -u | wc -l)

  v3=$(awk "BEGIN{print $v1/$numq}")
  v4=$(awk "BEGIN{print $v1/$numd}")

  printf "\tnum of unique queries: $numq\n"
  printf "\tnum of unique docs: $numd\n"

  printf "\tavg num of docs per query: $v3\n"
  printf "\tavg num of query per doc: $v4\n"
}

function print_query(){
  queryf=$1

  ntotalq=$(cat $queryf | sort -u | wc -l)
  ntotalqtext=$(cat $queryf | awk -F'\t' '{print $2}' | sort -u | wc -l)
  avgwords_q=$(cat $queryf | awk -F'\t' '{print $2}' | wc | awk '{print $2/$1}')

  printf "\n=== Queries === $1\n"
  printf "\tno. of unique $lang queryIDs: $ntotalq, unique text: $ntotalqtext \n"
  printf "\taverage no. of words: $avgwords_q\n"
}

function doc_stats() {
    printf "\n=== Docs ===\n"
    printf "from: $1\n"
    
    #eng_nw=$(cat $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -w)
    #src_nw=$(cat $TEMP_DIR/DOCS_$lang/$1/src/* | wc -w)
    #nlines=$(cat $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -l)
    #ndocs=$(ls $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -l)

    nw=$(cat $1/* | wc -w)
    nlines=$(cat $1/* | wc -l)
    ndocs=$(ls $1/* | wc -l)

    avg_nw_doc=$(awk "BEGIN{print $nw/$ndocs}")
    #src_avg_nw_doc=$(awk "BEGIN{print $src_nw/$ndocs}")
    if [ $nlines -eq 0 ]; then
      echo "no line info (joined doc not for MT)"
    else
      avg_nw_lin=$(awk "BEGIN{print $nw/$nlines}")
      avg_nlines=$(awk "BEGIN{print $nlines/$ndocs}")
      printf "\tnum lines: $nlines\n" 
      printf "\tavg nwords per line: $avg_nw_lin \n"
      printf "\tavg num lines per doc: $avg_nlines\n"
    fi
    #src_avg_nw_lin=$(awk "BEGIN{print $src_nw/$nlines}")

    printf "\tnum docs: $ndocs\n"
    #printf "\tavg nwords per line for src: $src_avg_nw_lin \n"
    printf "\tavg nwords per doc: $avg_nw_doc \n"
    #printf "\tavg nwords per doc for src: $src_avg_nw_doc \n"
}



conv_lang() {
  [[ "$1" == "english" ]] && lang="EN";
  [[ "$1" == "spanish" ]] && lang="ES";
  [[ "$1" == "german" ]] && lang="DE";
  [[ "$1" == "french" ]] && lang="FR";
  [[ "$1" == "finnish" ]] && lang="FI";
  [[ "$1" == "italian" ]] && lang="IT";
  [[ "$1" == "russian" ]] && lang="RU";
  [[ "$1" == "swedish" ]] && lang="SV";

  [[ "$2" == "lower" ]] && lang=`echo $lang | awk '{print tolower($0)}'`
  echo "$lang"
}

conv_encoding() {
  # check if utf-8, else convert
  fil=$1
  encoding=`file -b --mime-encoding $fil`

  if [[ $encoding != "utf-8" ]]; then
    [[ $encoding == "us-ascii" ]] && encoding="US-ASCII"
    [[ $encoding == "utf-16le" ]] && encoding="UTF-16LE"

    #echo "$encoding > utf-8 $fil"
    iconv -f ${encoding} -t UTF-8 $fil > ${fil}.t

    if [ $? -eq 0 ]; then
      mv ${fil}.t $fil
    else
      echo "encoding:$encoding, don't do anythng with $fil"
      rm ${fil}.t
    fi
  else
    echo "utf-8 > utf-8 $fil"
  fi
} 2>encoding.err



trec_map() {

  relf=$1
  resf=$2
  topics=$3
  writef=$4
  lang=$5
  system=$6

  score=$(./trec_eval/trec_eval -m map $relf.trec $resf | awk '{print $3}') || exit 1
  printf "$lang\t$system\t$topics\t$score\n" >> $writef
  echo "MAP Results written to $writef"

  #MAP score for each query
  ./trec_eval/trec_eval -q $relf.trec $resf | grep "map\s*query\s*" | awk '{print $2" "$3}' > $writef.each
  printf "MAP for each Query written to: $writef.each \n"

}
