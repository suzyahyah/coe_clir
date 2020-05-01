#!usr/bin/bash
# Author: Suzanna Sia

sstage=6 # In the style of Kaldi.
estage=6
baseline=0
processd=(bitext query mapping mt1 mt2 analysis) #(analysis query bitext mt1 mt2 mapping) #(analysis query bitext mapping mt1 mt2)
#processd=(mapping) #(analysis query bitext mapping mt1 mt2)

TEMP_DIR=/home/ssia/projects/coe_clir/data
DATA_DIR=/export/corpora5/MATERIAL/IARPA_MATERIAL_BASE-1
DATA_DIR2=/export/fs04/a12/mahsay/MATERIAL/1

mkdir -p $TEMP_DIR
declare -A L #languages
declare -A MT1

# this is correct
L=(
['SWAH']=${DATA_DIR}A
['TAGA']=${DATA_DIR}B
['SOMA']=${DATA_DIR}S
)

MT1=(
['SWAH']=${DATA_DIR2}A
['TAGA']=${DATA_DIR2}B
['SOMA']=${DATA_DIR2}S
)

rm_mk(){
  [ -d $1 ] && rm -r $1
  mkdir -p $1
}


train_test_split() {
  cat $1 | awk -v ftest="$1.test" -v ftrain="$1.train" -v fvalid="$1.valid" \
    '{if( NR%10 ==1){print $0 > fvalid} else {print $0 > ftrain}}'
#    '{if( NR%10 ==1){print $0 > ftest} else if (NR % 10 == 0){print \
#  $0 > fvalid} else {print $0 > ftrain}}'
}

# Extract Translations and Source document from the /translation/ folder
extract_translations() {
fn=$(
python3 - $1 $2 <<EOF
import sys
x = sys.argv[1]
print(x[x.rfind('/')+1:x.find('.')])
EOF
)
  cat $1 | awk -F'\t' '{print $2}' > $fn.tmp; mv $fn.tmp $2/src/$fn.txt
  cat $1 | awk -F'\t' '{print $3}' > $fn.tmp; mv $fn.tmp $2/human_eng/$fn.txt
}

doc_stats() {
    printf "\n=== $1, $2 ===\n"
    
    eng_nw=$(cat $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -w)
    src_nw=$(cat $TEMP_DIR/DOCS_$lang/$1/src/* | wc -w)
    nlines=$(cat $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -l)
    ndocs=$(ls $TEMP_DIR/DOCS_$lang/$1/$2/* | wc -l)

    eng_avg_nw_doc=$(awk "BEGIN{print $eng_nw/$ndocs}")
    src_avg_nw_doc=$(awk "BEGIN{print $src_nw/$ndocs}")
    eng_avg_nw_lin=$(awk "BEGIN{print $eng_nw/$nlines}")
    src_avg_nw_lin=$(awk "BEGIN{print $src_nw/$nlines}")
    avg_nlines=$(awk "BEGIN{print $nlines/$ndocs}")

    printf "\tnum lines: $nlines\n" 
    printf "\tnum docs: $ndocs\n"
    printf "\tavg num lines per doc: $avg_nlines\n"
    printf "\tavg nwords per line for eng: $eng_avg_nw_lin \n"
    printf "\tavg nwords per line for src: $src_avg_nw_lin \n"

    printf "\tavg nwords per doc for eng: $eng_avg_nw_doc \n"
    printf "\tavg nwords per doc for src: $src_avg_nw_doc \n"
}

index_query_doc() {
    printf "\n$1 - STAGE5: Index and Query $2 Trans Docs:\n"
    python src/main.py --lang $1 --mode doc --system $2 --dims 0

    score=$(./trec_eval/trec_eval -m map data/IRrels_$1/rels.tsv.dedup.trec \
      results/ranking_$1.txt.$2 | awk '{print $3}') || exit 1
    printf "$1\t$2\t00\t$score\n" >> results/all.txt

    ./trec_eval/trec_eval -q data/IRrels_$1/rels.tsv.dedup.trec \
      results/ranking_$1.txt.$2 | grep "map\s*query\s*" | awk '{print $2" "$3}' > results/each_map_$1.$2
    printf "Result written to: results/each_map_$1.$2\n"
}


# Stage 0: 5 start here.
for lang in "${!L[@]}"; do

  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  ##### Stage 0: Make Directories and Prepare data
    # Handle Queries, BiText (Training), ANALYSIS(Testing), MAPPING(Testing)

    # MAPPING
    if [[ "${processd[@]}" =~ "mapping" ]]; then

      rm_mk $TEMP_DIR/IRrels_$lang

      for i in 1 2 3; do
        sed "1d" ${L[$lang]}/ANALYSIS_ANNOTATION$i/query_annotation.tsv >> $TEMP_DIR/IRrels_$lang/rels.tsv
      done
      cat $TEMP_DIR/IRrels_$lang/rels.tsv | sed -e "s/\r//g" | sort -u > $TEMP_DIR/IRrels_$lang/rels.tsv.dedup
    fi


    if [[ "${processd[@]}" =~ "query" ]]; then
      printf "Processing query for $lang... \n"

      rm_mk $TEMP_DIR/QUERY_$lang

      qtmp=$TEMP_DIR/QUERY_$lang/q.txt.tmp
      relevfil=$TEMP_DIR/IRrels_$lang/rels.tsv.dedup

      cat ${L[$lang]}/QUERY{1,2,3}/query_list.tsv | sort -u > $qtmp

      # keep only queries that are in relevance file
      awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $relevfil $qtmp > $TEMP_DIR/QUERY_$lang/q.txt
      rm $qtmp

      python src/queryparser.py $TEMP_DIR/QUERY_$lang/q.txt
      # need to figure out what to do with duplicate queries
    fi
    
    ### BiText

    if [[ "${processd[@]}" =~ "bitext" ]]; then
      
      rm_mk $TEMP_DIR/DOCS_$lang/build-bitext
      rm_mk $TEMP_DIR/DOCS_$lang/build-bitext/eng
      rm_mk $TEMP_DIR/DOCS_$lang/build-bitext/src

      printf "Processing bitext for $lang...\n"
      if [[ "$lang" == "SOMA" ]]; then
        tempfn=$(ls ${L[$lang]}/BUILD/bitext/*_bitext.txt)
      else
        tempfn=$(ls ${L[$lang]}-BUILD_v1.0/bitext/*_bitext.txt)
      fi
      echo "Location of bitext is $tempfn"
      writefd=$TEMP_DIR/DOCS_$lang/build-bitext
      python src/extract_bitext.py $tempfn $writefd/src $writefd/eng

      v1=$(wc -l $tempfn | tail -1 | awk '{print $1}')
      v2=$(wc -l $TEMP_DIR/DOCS_$lang/build-bitext/eng/* | tail -1 | awk '{print $1}')
      v3=$(wc -l $TEMP_DIR/DOCS_$lang/build-bitext/src/* | tail -1 | awk '{print $1}')

      if [ "$v1" == "$v2" ] && [ "$v1" == "$v3" ]; then
        printf "nlines bitext $lang extracted: $v1\n"
      else
        printf "CRITICAL: Something wrong with BITEXT extraction.. $v1 $v2\n"
        exit 1
      fi
 
    fi

    # ANALYSIS DOCUMENTS
    if [[ "${processd[@]}" =~ "analysis" ]]; then
      printf "Processing analysis docs for $lang..\n"

      cdir=$TEMP_DIR/DOCS_$lang/ANALYSIS

      rm_mk $cdir/translation.tmp
      rm_mk $TEMP_DIR/DOCS_$lang/ANALYSIS/src
      rm_mk $TEMP_DIR/DOCS_$lang/ANALYSIS/human_eng

      #mkdir -p $TEMP_DIR/DOCS_$lang/ANALYSIS/translation

      cp ${L[$lang]}/ANALYSIS{1,2}/text/translation/* $cdir/translation.tmp
      # dont uncomment this
      #cp ${L[$lang]}/ANALYSIS{1,2}/text/translation/* $fol

      relevfil=$TEMP_DIR/IRrels_$lang/rels.tsv.dedup
      bash ./bin/find_match.sh $cdir translation.tmp translation $relevfil

      echo "extracting translations and src for $lang"
      for fil in `ls $TEMP_DIR/DOCS_$lang/ANALYSIS/translation/*.txt`;
      do 
        extract_translations $fil $TEMP_DIR/DOCS_$lang/ANALYSIS;
      done
      #v1=$(wc -l $TEMP_DIR/DOCS_$lang/ANALYSIS/translation/* | tail -1)
      #v2=$(wc -l $TEMP_DIR/DOCS_$lang/ANALYSIS/human_eng/* | tail -1)
      #v3=$(wc -l $TEMP_DIR/DOCS_$lang/ANALYSIS/src/* | tail -1)

      #if [ "$v1" == "$v2" ] && [ "$v1" == "$v3" ]; then
      #  printf "nlines bitext $lang extracted: $v1\n"
      #else
      #  printf "CRITICAL: Something wrong with ANALYSIS extraction.. $v1 $v2"
      #  exit 1
      #fi
    fi

    # MT Output
    mt1dir=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt1_eng
    if [[ "${processd[@]}" =~ "mt1" ]]; then
      
      rm_mk $mt1dir.tmp
      rm_mk $mt1dir

      printf "$lang mt1\n"
      ttfile=0.n

      [[ "$lang" == "SWAH" ]] && ttfile=tt18.n;
      [[ "$lang" == "TAGA" ]] && ttfile=tt20.n;
      [[ "$lang" == "SOMA" ]] && ttfile=tt53.n;

      cp ${MT1[$lang]}/ANALYSIS{1,2}/$ttfile/t_all/m1/* $mt1dir.tmp
      for fil in $mt1dir.tmp/*; do
        sed -i '/^$/d' $fil
      done

      cdir=$TEMP_DIR/DOCS_$lang/ANALYSIS
      relevfil=$TEMP_DIR/IRrels_$lang/rels.tsv.dedup
      bash ./bin/find_match.sh $cdir mt1_eng.tmp mt1_eng $relevfil

    fi
    
    if [[ "${processd[@]}" =~ "mt2" ]]; then
      printf "Processing mt2"
      bash ./bin/mt2.sh $lang

      cdir=$TEMP_DIR/DOCS_$lang/ANALYSIS
      relevfil=$TEMP_DIR/IRrels_$lang/rels.tsv.dedup
      bash ./bin/find_match.sh $cdir mt2_eng.tmp mt2_eng $relevfil
    fi

  fi 


  ##### Stage 1: Calculating Statistics
  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics:\n"

    ### Queries
    if [[ "${processd[@]}" =~ "query" ]]; then
      ntotalq=$(cat $TEMP_DIR/QUERY_$lang/q.txt.qp | sort -u | wc -l)
      ntotalqtext=$(cat $TEMP_DIR/QUERY_$lang/q.txt.qp | awk -F'\t' '{print $2}' | sort -u | wc -l)
      avgwords_q=$(cat $TEMP_DIR/QUERY_$lang/q.txt.qp | awk -F'\t' '{print $2}' | wc | awk '{print $2/$1}')

      printf "\n=== Queries === \n"
      printf "\tno. of unique $lang queryIDs: $ntotalq, unique text: $ntotalqtext \n"
      printf "\taverage no. of words: $avgwords_q\n"
    fi

    ### BiText
    [[ "${processd[@]}" =~ "bitext" ]] && doc_stats "build-bitext" "eng";

    # ANALYSIS Documents
    [[ "${processd[@]}" =~ "analysis" ]] && doc_stats "ANALYSIS" "human_eng";

    # MT1 English Docs
    [[ "${processd[@]}" =~ "mt1" ]] && doc_stats "ANALYSIS" "mt1_eng";

    # MT2 English Docs
    [[ "${processd[@]}" =~ "mt2" ]] && doc_stats "ANALYSIS" "mt2_eng";


    ##### Handling mapping 

    if [[ "${processd[@]}" =~ "mapping" ]]; then
      printf "\n=== mapping ===\n"
      v1=$(wc -l $TEMP_DIR/IRrels_$lang/rels.tsv | awk '{print $1}')
      v2=$(wc -l $TEMP_DIR/IRrels_$lang/rels.tsv.dedup | awk '{print $1}')  
      printf "\toriginal num mappings: $v1, after dedup: $v2\n"

      numq=$(awk '{print $1}' $TEMP_DIR/IRrels_$lang/rels.tsv.dedup | sort -u | wc -l)
      numd=$(awk '{print $2}' $TEMP_DIR/IRrels_$lang/rels.tsv.dedup | sort -u | wc -l)

      v3=$(awk "BEGIN{print $v2/$numq}")
      v4=$(awk "BEGIN{print $v2/$numd}")

      printf "\tnum of unique queries: $numq\n"
      printf "\tnum of unique docs: $numd\n"

      printf "\tavg num of docs per query: $v3\n"
      printf "\tavg num of query per doc: $v4\n"

      #gawk -i inplace '{print $1"\tQ0\t"$2"\t1"}' $TEMP_DIR/IRrels_$lang/rels.tsv.dedup 
      # trec eval format
      awk '{print $1"\tQ0\t"$2"\t1"}' $TEMP_DIR/IRrels_$lang/rels.tsv.dedup \
      > $TEMP_DIR/IRrels_$lang/rels.tsv.dedup.trec
    fi
  fi # end of stage 1

  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
    # We usually do stopword removal for Topic Modeling (bitext), for MT outputs BM25 TF-IDF weights the
    # tokens and hence we should not do stopword removal. However for BM25 docs we want to do digit
    # and punctuation removal, and lowercase for preprocessing. 
    printf "\n$lang - STAGE2: Preprocessing:\n"
    python src/preprocess.py --lang "$lang" --mode "tm"

    #[[ "${processd[@]}" =~ "analysis" ]] && python src/preprocess.py --lang "$lang" --mode "doc_human";
    #[[ "${processd[@]}" =~ "mt1" ]] && python src/preprocess.py --lang "$lang" --mode "doc_mt1";
    #[[ "${processd[@]}" =~ "mt2" ]] && python src/preprocess.py --lang "$lang" --mode "doc_mt2";

  fi

  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
    printf "\n$lang - STAGE3: train topic model:\n"
    #for k in 10 20 50 100 200 300 400 500; do
    for k in 600 700; do
      bash ./bin/runPolyTM.sh $lang $k
    done
  fi

  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
    printf "\n$lang - STAGE4: test topic model:\n"
#    for k in 10 20 50 100 200 300 400 500; do
    #for k in 600 700; do
    for k in 400; do # take the best TM

      python src/main.py --lang $lang --mode tm --dims $k --baseline $baseline
      score=$(./trec_eval/trec_eval -m map data/IRrels_$lang/rels.tsv.dedup.trec \
      results/ranking_$lang.txt.tm | awk '{print $3}')

      ./trec_eval/trec_eval -q data/IRrels_$lang/rels.tsv.dedup.trec \
      results/ranking_$lang.txt.tm | grep "map\s*query\s*" | awk '{print $2" "$3}' > results/each_map_$lang.tm
 

      if [ $baseline -eq 1 ]; then
        printf "$lang\ttopic\t$k\t$score\n" >> results/all.txt.baseline_tm
      else
        printf "$lang\ttopic\t$k\t$score\n" >> results/all.txt
      fi
    done
  fi


  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then

    [[ "${processd[@]}" =~ "analysis" ]] && index_query_doc "$lang" "human";
      
    [[ "${processd[@]}" =~ "mt1" ]] && index_query_doc "$lang" "mt1";

    [[ "${processd[@]}" =~ "mt2" ]] && index_query_doc "$lang" "mt2";
 
  fi

  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then
    for w in 0.01 0.05 0.1 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.5 0.55; do
      python src/combine_models.py $lang $w
      printf "weight $w $lang "
      ./trec_eval/trec_eval -m map data/IRrels_$lang/rels.tsv.dedup.trec results/combine_$lang.txt
    done
  fi


done
