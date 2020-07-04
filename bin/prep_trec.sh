#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

# This Script prepares Trec Data for Stage 0-7 of the Pipeline

# Stage 0: Make Directories and Prepare Data
# Stage 1: Merge Queries, RelAssess, Docs
# Stage 2: Calculate statistics
# Stage 3: Preprocessing Query and Document
# Stage 4: Train Polylingual Topic Models on BiText
# Stage 5: Test Topic Models
# Stage 6: Index and Retrieve Docs
# Stage 7: Combine Doc Retrieval and TM models

sstage=2
estage=2
translate=0
reset=0 # copies all directories
baseline=0
query_english_only=1

processd=(doc query rel bitext)

# Original DaGta Directory
TRECDIR_org=/home/hltcoe/kduh/data/ir/trec/

# New Save Directory 
TRECDIR=/home/hltcoe/ssia/trec

DOCS=$TRECDIR
RELS=$TRECDIR/RelAssess
QUERIES=$TRECDIR/Topics
BITEXT=/home/hltcoe/ssia/parallel_corpora/split

declare -A L=(
#['arabic']=${DOCS}/arabic
['chinese']=${DOCS}/chinese
#['spanish']=${DOCS}/spanish
)

declare -A L_org=(
#['arabic']=${DOCS}/arabic
['chinese']=${DOCS}/chinese
#['spanish']=${DOCS}/spanish
)


# removing and copy entire directories
if [ $reset -eq 1 ]; then
  [ -d $TRECDIR ] && rm -r $TRECDIR
  cp -r $TRECDIR_org $TRECDIR
  mkdir -p $QUERIES
fi


# Stage 0: Get Data
if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

  if [[ "${processd[@]}" =~ "query" ]]; then
    for lang in "${!L[@]}"; do
      # process title and alltext for trecs56 and trec9
      # trecs56 has queries CH1-CH54
      # trec9 has queries CH55-CH79
    #######################################################
    # Extract English Queries only
    #######################################################
 
      if [[ $lang == "chinese" ]] && [[ $query_english_only -eq 1 ]]; then
        rm_mk $QUERIES/QUERY_english
        cat ${L[$lang]}/trecs56/topics/all.topics.trec56.utf8 > $QUERIES/QUERY_english/all_topics.txt
        cat ${L[$lang]}/trec9/topics/xling9-topics.txt >> $QUERIES/QUERY_english/all_topics.txt
        python src/docparser.py query $QUERIES/QUERY_english/all_topics.txt $QUERIES/QUERY_english
      fi
    done
  fi

  if [[ "${processd[@]}" =~ "rel" ]]; then
    #######################################################
    # Extract relevance assessments
    #######################################################

    for lang in "${!L[@]}"; do

      mkdir -p $RELS
      echo "Processing rel files..."
      relf=$RELS/all_yrs/qrels_${lang}.txt

      [[ -f $relf ]] && rm $relf

      if [[ $lang == "chinese" ]]; then
        cat ${L[$lang]}/trec9/qrels/xling9_qrels > $relf
        cat ${L[$lang]}/trecs56/qrels/qrels_trec56 >> $relf
      fi

      # Keep only the rel mappings "1" in 4th column
      awk '{ if ($4==1) {print }}' $relf > $relf.temp
      awk '{print "query"$1" "$3}' $relf.temp > $relf
      rm $relf.temp
      echo "written relf to $relf"
      
    done
  fi
    
  if [[ "${processd[@]}" =~ "doc" ]]; then
    
    for lang in "${!L[@]}"; do
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
    done
  fi

  if [[ $translate -eq 1 ]]; then
  #######################################################
  # Translate Documents
  #######################################################
    # Translate Target Language to English
    # Languages supported: Chinese
    # Modify src/translate.py if the translation system changes.

    # For this we use pre-trained fairseq
    # Note this requires rtx gpus on COE-Grid

    # Translate a specific folder manually or everything ending with {name}_txt
    # The new documents will be in {name}_txt_en

    for lang in "${!L[@]}"; do
      for fild in `ls -d ${L[$lang]}/trec{9,s56}/docs/* | grep "_txt$"`; do
        rm_mk ${fild}_en
      #for $fild in `ls -d ${L[$lang]}/trec56s/docs/* | grep "_txt$"`; do
        echo "Translating $lang.. $fild"
        python src/translate.py $lang $fild
      done
    done
  fi
fi

if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
  #######################################################
  # Stage 1: Merge Query, Rel, Doc
  #######################################################
 
  # After processing all the files, do a 3way join such that
  # queries must have a valid line in the rels file
  # relevant lines must have a valid query
  # query must have valid document.
  # the logic for this is in src/merge_keys.py

  for lang in "${!L[@]}"; do
    # copy translated into all_docs_en
    # copy original language into all_docs
#    rm_mk ${L[$lang]}/all_docs_en
#    rm_mk ${L[$lang]}/all_docs_src
#
#    if [ $lang == "chinese" ]; then
#      for subdir in `ls -d ${L[$lang]}/trec{9,s56}/docs/*_txt_en`; do
#        echo "Copying $subdir to all_docs_en.."
#        cp -l $subdir/* ${L[$lang]}/all_docs_en
#      done
#
#      for subdir in `ls -d ${L[$lang]}/trec{9,s56}/docs/*_txt`; do
#        echo "Copying $subdir to all_docs_src.."
#        cp -l $subdir/* ${L[$lang]}/all_docs_src
#      done
#    fi

    echo "Merging relf, docids, qids"
    relf=$RELS/all_yrs/qrels_${lang}.txt
    query1=$QUERIES/QUERY_english/query_all.txt
    query2=$QUERIES/QUERY_english/query_title.txt
    fild=${L[$lang]}/all_docs_src

    [ ! -f $relf ] && echo "Error: run Stage0:rel to generate $relf first" && exit 1
    [ ! -f $query1 ] && echo "Error: run Stage0: query to generate $query1 first" && exit 1
    [ ! -d $fild ] && echo "Error: run Stage0: doc to generate $fild first" && exit 1

    python src/merge_keys.py "$relf" "$query1" "$fild" $lang
    python src/merge_keys.py "$relf" "$query2" "$fild" $lang

    # Prepare trec format after merging
    [[ -f $relf.trec ]] && rm $relf.trec
    awk '{print $1"\tQ0\t"$2"\t1"}' $relf > $relf.trec
  done
fi # end of stage 1-merge


if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
  #######################################################
  # Stage 2: Calculate statistics
  #######################################################

  for lang in "${!L[@]}"; do
    printf "\n$lang - STAGE2: Calculating Statistics"
    ### Queries
    if [[ "${processd[@]}" =~ "query" ]]; then
      print_query $QUERIES/QUERY_english/query_all_${lang}.txt
      print_query $QUERIES/QUERY_english/query_title_${lang}.txt
    fi

    ### BiText
    [[ "${processd[@]}" =~ "bitext" ]] && doc_stats $BITEXT/DOCS_$lang/build-bitext/eng

    # Documents
    [[ "${processd[@]}" =~ "doc" ]] && doc_stats ${L[$lang]}/all_docs_en
    [[ "${processd[@]}" =~ "doc" ]] && doc_stats ${L[$lang]}/all_docs_src

    ### Handling rel 
    [[ "${processd[@]}" =~ "rel" ]] && print_rel $RELS/all_yrs/qrels_${lang}.txt
  done
fi # End Stage 2



if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
  #######################################################
  # Stage 3: Preprocessing Query and Document
  #######################################################
  for lang in "${!L[@]}"; do
    printf "\n$lang - STAGE3: Preprocessing"
    # Train CrossLingual Topic Models
    # Convert source language to Topic Vector
    # Convert query to Topic Vector
    # Index and Retrieve for Topic Models
    # get stopwords
    stopwordf=assets/stopwords_$lang.txt
  
    # Process bitext for Topic Model
    if [[ "${processd[@]}" =~ "bitext" ]]; then

      bitext1=$BITEXT/DOCS_$lang/build-bitext/eng
      bitext2=$BITEXT/DOCS_$lang/build-bitext/src
      #rm_mk "${bitext1}_tm"
      #rm_mk "${bitext2}_tm"
      #python src/preprocess.py --mode "tm" --docdir $bitext1 --sw assets/stopwords_en.txt
      #python src/preprocess.py --mode "tm" --docdir $bitext2 --sw $stopwordf

      #ls ${bitext1}_tm | xargs -n1 -I % sed -i 's/^headline$//g' ${bitext1}_tm/%
      #ls ${bitext2}_tm | xargs -n1 -I % sed -i 's/^headline$//g' ${bitext2}_tm/%

      if [ $lang == "chinese" ]; then
        mkdir -p ${bitext2}_tm.temp
        python src/preprocess.py --mode "tokenize" --docdir ${bitext2}_tm
        mv ${bitext2}_tm.temp ${bitext2}_tm
      fi
      

    fi

    # Process the Query for Topic Model and for BM25
    if [[ "${processd[@]}" =~ "query" ]]; then
      queryf_all=$QUERIES/QUERY_english/query_all_${lang}.txt
      queryf_title=$QUERIES/QUERY_english/query_title_${lang}.txt

      python src/preprocess.py --mode "tm" --fn $queryf_all --sw assets/stopwords_en.txt 
      python src/preprocess.py --mode "tm" --fn $queryf_title --sw assets/stopwords_en.txt 

      python src/preprocess.py --mode "bm25" --fn $queryf_all 
      python src/preprocess.py --mode "bm25" --fn $queryf_title
    fi

    # Process Src Docs for Topic Model and Translated(English) Doc for BM25
    # The new documents will be suffixed by _bm25 and _tm
    # We don't use stopwords for bm25 as they will be downweighted by the algorithm
    if [[ "${processd[@]}" =~ "doc" ]]; then
      src_docs=${L[$lang]}/all_docs_src
      rm_mk "${src_docs}_tm"
      python src/preprocess.py --mode "tm" --docdir $src_docs --sw $stopwordf
      if [ $lang == "chinese" ]; then
        mkdir -p ${src_docs}_tm.temp
        python src/preprocess.py --mode "tokenize" --docdir ${src_docs}_tm
        rm -r ${src_docs}_tm
        mv ${src_docs}_tm.temp ${src_docs}_tm
      fi
 

      #en_docs=${L[$lang]}/all_docs_en
      #rm_mk ${en_docs}_bm25
      #python src/preprocess.py --mode "bm25" --docdir $en_docs 
    fi
  done
fi

if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
  #######################################################
  # Stage 4: Train Polylingual Topic Models on BiText
  #######################################################

  for lang in "${!L[@]}"; do
    printf "\n$lang - STAGE4: train topic model:\n"
    #for k in 10 20 50 100 200 300 400 500; do
    BITEXTD=$BITEXT/DOCS_$lang/build-bitext
    TESTD=${L[$lang]}/all_docs_src

    for qtype in all title; do
      QUERYF=$QUERIES/QUERY_english/query_${qtype}_${lang}.txt.tm
#      for k in 10 20; do
      #for k in 10 20 50 100 200 300 400; do
      #for k in 20 50 100 200; do
      for k in 200; do
        bash ./bin/runPolyTM.sh train $BITEXTD $lang $k
        bash ./bin/runPolyTM.sh infer $BITEXTD $lang $k $TESTD $QUERYF $qtype
      done
    done
  done # end lang
fi 


if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
  #######################################################
  # Stage 5: Test Topic Model 
  #######################################################
  for lang in "${!L[@]}"; do
    printf "\n$lang - STAGE5: test topic model:\n"
    mkdir -p results/TREC/$lang

    if [ $baseline -eq 1 ]; then
      suffix=".baseline_tm"
    else
      suffix=""
    fi

    for qtype in title all; do

      writef=results/TREC/$lang/tm.$qtype.map
      [[ -f $writef ]] && rm $writef
      echo "lang\tmodel\ttopics\tscore\n" > $writef

      for k in 20 50 100 200; do 

        qfn=malletfiles/$lang/query_$qtype.$k
        tfn=malletfiles/$lang/SrcTopics.$k

        relf=$RELS/all_yrs/qrels_${lang}.txt

        resf=results/TREC/$lang/tm.$qtype.ranking.$k

        [[ ! -f $qfn ]] && echo "$qfn does not exist, run infererence from stage4" && exit 1
        [[ ! -f $tfn ]] && echo "$tfn does not exist, run infererence from stage4" && exit 1
        [[ ! -f $relf ]] && echo "$relf does not exist, run stage0-1" && exit 1
        echo "Stage 5: Testing topic model retrieval $lang ${k} topics"
        python src/main.py --mode tm --dims $k \
                          --query_fn $qfn --target_fn $tfn --resf $resf

        trec_map "$relf" "$resf" "$k" "${writef}${suffix}" "$lang" "tm" 
      done
    done
  done
fi # End Stage 5


if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then
  #######################################################
  # Stage 6: Index and Retrieve 
  #######################################################
  for lang in "${!L[@]}"; do
    for qtype in title all; do
      qfn=$QUERIES/QUERY_english/query_${qtype}_${lang}.txt.bm25
      tfn=${L[$lang]}/all_docs_en_bm25
      relf=$RELS/all_yrs/qrels_${lang}.txt
      resf=results/TREC/$lang/bm25.${qtype}.ranking
      writef=results/TREC/$lang/bm25.$qtype.map
      [[ -f $writef ]] && rm $writef
      echo "lang\tmodel\ttopics\tscore\n" > $writef


      python src/main.py --mode doc --dims 0 \
                        --query_fn $qfn --target_fn $tfn --resf $resf

      trec_map "$relf" "$resf" "00" "$writef" "$lang" "doc" 
    done
  done 
fi # End stage 6

if [ $sstage -le 7 ] && [ $estage -ge 7 ]; then
  #######################################################
  # Stage 7: Combine models
  #######################################################
  for lang in "${!L[@]}"; do
    echo "Combining models for $lang..."
    relf=$RELS/all_yrs/qrels_${lang}.txt
    for qtype in all title; do
      outf=results/TREC/${lang}/combine.$qtype
      [[ -f $outf.map ]] && rm $outf.map && rm $outf.ranking && $outf.ranking.tmp
      echo "lang\tmodel\ttopics\tscore\n" > $outf


      maxk=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k}' results/TREC/$lang/tm.$qtype.map`
      echo "querytype:$qtype, max topic:$maxk" 

      tmrank=results/TREC/${lang}/tm.${qtype}.ranking.$maxk
      docrank=results/TREC/${lang}/bm25.${qtype}.ranking

      echo "Searching over interpolation weights:"
      # (1-w) score1 + w *score2
      for w in `seq 0 0.05 1`; do 
      #for w in 0.05; do 
        python src/combine_models.py $w $tmrank $docrank $outf.ranking
        printf "$w "
        ./trec_eval/trec_eval -m map ${relf}.trec $outf.ranking > $outf.ranking.tmp
        awk -v k=$maxk -v w=$w '{print k" "w" "$3}' $outf.ranking.tmp >> $outf.map
      done
      echo "Written to: $outf.map" 
      maxw=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print k" "max}' $outf.map`
      echo "querytype: $qtype, best interpolation weight, map score: $maxw"
    done
  done
fi # End Stage 7
