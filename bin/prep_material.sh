#!usr/bin/bash
# Author: Suzanna Sia

source ./bin/utils.sh

# document types to process for stage0 to stage6.
processd=(mt1 mt2)  #query rel mt1 mt2 bitext) 
random_topic_vectors=0 # Used as a dumb baseline/sanity check.

# start stage and end stage (inclusive)
sstage=7
estage=7

# Stage0: Get Data
# Stage1: Merge Queries, Rel, Docs
# Stage2: Data statistics
# Stage3: Data Preprocessing
# Stage4: Polylingual Topic Modeling
# Stage5: Index and Query Elastic Search (Topic Vectors)
# Stage6: Index and Query Elastic search (Text)
# Stage7: Combine trained models

TEMP_DIR=/home/ssia/projects/coe_clir/data
DATA_DIR=/export/corpora5/MATERIAL/IARPA_MATERIAL_BASE-1
DATA_DIR2=/export/fs04/a12/mahsay/MATERIAL/1
TREC_EVALDIR=/home/ssia/projects/coe_clir/trec_eval

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
#['SWAH']=${DATA_DIR2}A
['TAGA']=${DATA_DIR2}B
['SOMA']=${DATA_DIR2}S
)


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


# Stage 0: 5 start here.
for lang in "${!L[@]}"; do

  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  ##### Stage 0: Make Directories and Prepare data
    # Handle Queries, BiText (Training), ANALYSIS(Testing), rel(Testing)
    # rel
    if [[ "${processd[@]}" =~ "rel" ]]; then
      printf "Getting rel files for $lang...\n"
      rm_mk $TEMP_DIR/IRrels_$lang
      for i in 1 2 3; do
        sed "1d" ${L[$lang]}/ANALYSIS_ANNOTATION$i/query_annotation.tsv >> $TEMP_DIR/IRrels_$lang/rels.tsv
      done
      cat $TEMP_DIR/IRrels_$lang/rels.tsv | sed -e "s/\r//g" | sort -u > $TEMP_DIR/IRrels_$lang/rels.tsv.tmp
    fi

    if [[ "${processd[@]}" =~ "query" ]]; then
      printf "Getting queries for $lang... \n"
      rm_mk $TEMP_DIR/QUERY_$lang
      qtmp=$TEMP_DIR/QUERY_$lang/q.txt.tmp
      cat ${L[$lang]}/QUERY{1,2,3}/query_list.tsv | sort -u > $qtmp
      python src/queryparser.py $qtmp
    fi

    # ANALYSIS DOCUMENTS
    if [[ "${processd[@]}" =~ "docs" ]]; then
      printf "Getting target docs for $lang..\n"
      cdir=$TEMP_DIR/DOCS_$lang/ANALYSIS

      rm_mk $cdir/translation
      rm_mk $TEMP_DIR/DOCS_$lang/ANALYSIS/src
      rm_mk $TEMP_DIR/DOCS_$lang/ANALYSIS/human_eng
      cp ${L[$lang]}/ANALYSIS{1,2}/text/translation/* $cdir/translation

      echo "Extracting translations and src for $lang"
      for fil in `ls $TEMP_DIR/DOCS_$lang/ANALYSIS/translation/*.txt`;
      do 
        extract_translations $fil $TEMP_DIR/DOCS_$lang/ANALYSIS;
      done
 
    fi
    # MT Output
    mt1dir=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt1_eng
    if [[ "${processd[@]}" =~ "mt1" ]]; then
      
      rm_mk $mt1dir.tmp
      rm_mk $mt1dir

      printf "Getting docs for $lang mt1\n"
      ttfile=0.n

      [[ "$lang" == "SWAH" ]] && ttfile=tt18.n;
      [[ "$lang" == "TAGA" ]] && ttfile=tt20.n;
      [[ "$lang" == "SOMA" ]] && ttfile=tt53.n;

      cp ${MT1[$lang]}/ANALYSIS{1,2}/$ttfile/t_all/m1/* $mt1dir
      for fil in $mt1dir/*; do
        sed -i '/^$/d' $fil
      done
    fi
    
    # MT2  
    if [[ "${processd[@]}" =~ "mt2" ]]; then
      printf "Getting docs for $lang  mt2\n"
      bash ./bin/mt2.sh $lang
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
  fi 


  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    ### Do 3-way join
    echo "Merging relf, docids, qids"
    relf=$TEMP_DIR/IRrels_$lang/rels.tsv.tmp
    queryf=$TEMP_DIR/QUERY_$lang/q.txt.tmp.qp
    docfold=$TEMP_DIR/DOCS_$lang/ANALYSIS/translation

    [ ! -f $relf ] && echo "Error: run Stage0:rel to generate $relf first" && exit 1
    [ ! -f $query1 ] && echo "Error: run Stage0: query to generate $query1 first" && exit 1
    [ ! -d $fild ] && echo "Error: run Stage0: doc to generate $fild first" && exit 1

    python src/merge_keys.py "$relf" "$queryf" "$docfold"
  fi

  ##### Stage 1: Calculating Statistics
  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics:\n"

    ### Queries
    [[ "${processd[@]}" =~ "query" ]] && print_query $TEMP_DIR/QUERY_$lang/q.txt

    ### BiText
    [[ "${processd[@]}" =~ "bitext" ]] && doc_stats $TEMP_DIR/DOCS_$lang/build-bitext/eng

    # ANALYSIS Documents
    ANALYSISD=$TEMP_DIR/DOCS_$lang/ANALYSIS

    [[ "${processd[@]}" =~ "docs" ]] && doc_stats $ANALYSISD/human_eng
    [[ "${processd[@]}" =~ "docs" ]] && doc_stats $ANALYSISD/src

    # MT1 English Docs
    [[ "${processd[@]}" =~ "mt1" ]] && doc_stats $ANALYSISD/mt1_eng

    # MT2 English Docs
    [[ "${processd[@]}" =~ "mt2" ]] && doc_stats $ANALYSISD/mt2_eng


    ##### Handling rel 

    if [[ "${processd[@]}" =~ "rel" ]]; then
      relsf=$TEMP_DIR/IRrels_$lang/rels.txt
      print_rel $relsf
      awk '{print $1"\tQ0\t"$2"\t1"}' $relsf > $relsf.trec
    fi
  fi # end of stage 1

  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
    # We usually do stopword removal for Topic Modeling (bitext), 
    # for MT outputs BM25 TF-IDF weights the
    # tokens and hence we should not do stopword removal. 
    # However for BM25 docs we want to do digit
    # and punctuation removal, and lowercase for preprocessing. 
    printf "\n$lang - STAGE3: Preprocessing:\n"
    #python src/preprocess.py --lang "$lang" --mode "tm"
    stopwordf=assets/stopwords_$lang.txt

    if [[ "${processd[@]}" =~ "bitext" ]]; then
      bitext1=$TEMP_DIR/DOCS_$lang/build-bitext/eng
      bitext2=$TEMP_DIR/DOCS_$lang/build-bitext/src
      rm_mk "${bitext1}_tm"
      rm_mk "${bitext2}_tm"
      python src/preprocess.py --mode "tm" --docdir $bitext1 --sw assets/stopwords_en.txt
      python src/preprocess.py --mode "tm" --docdir $bitext2 --sw $stopwordf
    fi

    if [[ "${processd[@]}" =~ "query" ]]; then
      queryf=$TEMP_DIR/QUERY_$lang/q.txt
      python src/preprocess.py --mode "tm" --fn $queryf --sw assets/stopwords_en.txt 
    fi
    

    # Process Src Docs for Topic Model and English Doc for BM25
    if [[ "${processd[@]}" =~ "docs" ]]; then
      docs_src=$TEMP_DIR/DOCS_$lang/ANALYSIS/src
      rm_mk "${docs_src}_tm"
      python src/preprocess.py --mode "tm" --docdir $docs_src --sw $stopwordf

      hudir=$TEMP_DIR/DOCS_$lang/ANALYSIS/human_eng
      rm_mk ${hudir}_bm25
      python src/preprocess.py --mode "bm25" --docdir $hudir
    fi

    # Process Translated English Docs for BM25
    if [[ "${processd[@]}" =~ "mt1" ]]; then
      mt1dir=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt1_eng
      rm_mk ${mt1dir}_bm25
      python src/preprocess.py --mode "bm25" --docdir $mt1dir
    fi

    # Process Translated English Docs for BM25
    if [[ "${processd[@]}" =~ "mt2" ]]; then
      mt2dir=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt2_eng
      rm_mk ${mt2dir}_bm25
      python src/preprocess.py --mode "bm25" --docdir $mt2dir
    fi

  fi # end of stage 3

  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
    printf "\n$lang - STAGE4: train topic model:\n"
    BITEXTD=$TEMP_DIR/DOCS_$lang/build-bitext
    TESTD=$TEMP_DIR/DOCS_$lang/ANALYSIS/src
    QUERYF=$TEMP_DIR/QUERY_$lang/q.txt.tm
    qtype=title
    #for k in 10 20 50 100 200 300 400 500; do
    for k in 20 50 100 200; do
    #for k in 20; do
      bash ./bin/runPolyTM.sh train $BITEXTD $lang $k
      bash ./bin/runPolyTM.sh infer $BITEXTD $lang $k $TESTD $QUERYF $qtype
    done
  fi

  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
    printf "\n$lang - STAGE5: test topic model:\n"
#    for k in 10 20 50 100 200 300 400 500; do
    #for k in 600 700; do
    qtype=title
    mkdir -p results/MATERIAL/$lang
    writef=results/MATERIAL/$lang/tm.$qtype.map
    for k in 100; do # take the best TM
      qfn=malletfiles/$lang/query_$qtype.$k
      tfn=malletfiles/$lang/SrcTopics.$k
      resf=results/MATERIAL/$lang/tm.$qtype.ranking.$k
      relf=$TEMP_DIR/IRrels_$lang/rels.txt

      echo "Stage 5: Testing topic model retrieval $lang ${k} topics"
      echo $qfn 

      python src/main.py --mode tm --dims $k --query_fn $qfn --target_fn $tfn --resf $resf
      trec_map "$relf" "$resf" "$k" "${writef}${suffix}" "$lang" "tm"

    done
  fi


  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then

    qfn=$TEMP_DIR/QUERY_$lang/q.txt.tmp.qp
    relf=$TEMP_DIR/IRrels_$lang/rels.txt
    qtype=title

    if [[ "${processd[@]}" =~ "docs" ]]; then
      tfn=$TEMP_DIR/DOCS_$lang/ANALYSIS/human_eng_bm25
      resf=results/MATERIAL/$lang/human.${qtype}.ranking
      writef=results/MATERIAL/$lang/human.${qtype}.map
      index_query_doc $qfn $tfn $relf $resf $writef
    fi


    if [[ "${processd[@]}" =~ "mt1" ]]; then
      tfn=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt1_eng_bm25
      resf=results/MATERIAL/$lang/mt1.${qtype}.ranking
      writef=results/MATERIAL/$lang/mt1.${qtype}.map
      index_query_doc $qfn $tfn $relf $resf $writef
    fi

      
    if [[ "${processd[@]}" =~ "mt2" ]]; then
      tfn=$TEMP_DIR/DOCS_$lang/ANALYSIS/mt2_eng_bm25
      resf=results/MATERIAL/$lang/mt2.${qtype}.ranking
      writef=results/MATERIAL/$lang/mt2.${qtype}.map
      index_query_doc $qfn $tfn $relf $resf $writef
    fi
  fi

  if [ $sstage -le 7 ] && [ $estage -ge 7 ]; then
  #  for w in 0.01 0.05 0.1 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.5 0.55; do
  #    python src/combine_models.py $lang $w
  #    printf "weight $w $lang "
  #    ./trec_eval/trec_eval -m map data/IRrels_$lang/rels.txt.trec results/combine_$lang.txt
  #  done
    relf=$TEMP_DIR/IRrels_$lang/rels.txt
    outf=results/MATERIAL/$lang/combine.title
    tmmap=results/MATERIAL/$lang/tm.title.map
    tmrank=results/MATERIAL/$lang/tm.title.ranking

    if [[ "${processd[@]}" =~ "docs" ]]; then
      docrank=results/MATERIAL/$lang/human.title.ranking
      echo "combine for docs.."
      combine_model_sweep $relf $outf $tmmap $tmrank $docrank
    fi


    if [[ "${processd[@]}" =~ "mt1" ]]; then
      docrank=results/MATERIAL/$lang/mt1.title.ranking
      echo "combine for mt1 , tm.."
      combine_model_sweep $relf $outf $tmmap $tmrank $docrank
    fi

    if [[ "${processd[@]}" =~ "mt2" ]]; then
      docrank=results/MATERIAL/$lang/mt2.title.ranking
      echo "combine for mt2, tm .."
      combine_model_sweep $relf $outf $tmmap $tmrank $docrank
    fi

  fi
done
