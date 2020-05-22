#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

# This Script prepares Clef Data before it can be used in Stage 1-5 of the Pipeline
# This is Stage 0: Getting/Preparing Data

sstage=3
estage=3
translate=0
reset=0 # copies all directories
merge=0
baseline=0

processd=()

DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04

DIR0003=/home/hltcoe/ssia/clef00-03
DIR0304=/home/hltcoe/ssia/clef03-04

DOCS=$DIR0003/DocumentData/DataCollections
DOCS_org=$DIR0003_org/DocumentData/DataCollections

RELS=$DIR0003/RelAssess
QUERIES=$DIR0003/Topics
BITEXT=/home/hltcoe/ssia/parallel_corpora/split

declare -A L
declare -A L_org

L=(
#['english']=${DOCS}/English_data
#['french']=${DOCS}/French_data
['german']=${DOCS}/German_data
#['russian']=${DOCS}/Russian_data
#['spanish']=${DOCS}/Spanish_data
)

L_org=(
#['english']=${DOCS_org}/English_data
#['french']=${DOCS_org}/French_data
['german']=${DOCS_org}/German_data
#['russian']=${DOCS_org}/Russian_data
#['spanish']=${DOCS_org}/Spanish_data
)

# removing and copy entire directories
if [ $reset -eq 1 ]; then
  [ -d $DIR0003 ] && rm -r $DIR0003
  [ -d $DIR0304 ] && rm -r $DIR0304
  cp -r $DIR0003_org $DIR0003
  cp -r $DIR0304_org $DIR0304
fi


# Stage 0: Get Data
if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then

  # Folder and file renaming for consistency    
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

    #######################################################
    # Extract English Queries
    #######################################################

    lang=english
    rm_mk $QUERIES/QUERY_${lang}
    for yr in 00 01 02 03; do #2000 is broken
      #langt=`conv_lang $lang lower`
      langt=en
      fil=$QUERIES/topics20${yr}/Top-${langt}${yr}.txt
      conv_encoding $fil
      python src/docparser.py query $fil $QUERIES/QUERY_${lang} $yr
    done
    # Construct two versions of the query, one with title only 'query_title.txt', and the other with query,
    # description, and narraive 'query_all.txt'
    cat $QUERIES/QUERY_${lang}/query{00,01,02,03}_title.txt > $QUERIES/QUERY_${lang}/query_title.txt
    cat $QUERIES/QUERY_${lang}/query{00,01,02,03}_all.txt > $QUERIES/QUERY_${lang}/query_all.txt
  fi

  if [[ "${processd[@]}" =~ "rel" ]]; then
    [ -d $DIR0003/RelAssess ] && rm -r $DIR0003/RelAssess
    cp -r $DIR0003_org/RelAssess $DIR0003

    mv $RELS/2000rels/biling_qrels $RELS/2000rels/qrels_english
    mv $RELS/2001rels/qrels_bilingual $RELS/2001rels/qrels_english
    
    for lang in "${!L[@]}"; do
      mv $RELS/2000rels/${lang}_qrels $RELS/2000rels/qrels_${lang}
      lang2=`conv_lang $lang`
      mv $RELS/2002rels/qrels_${lang2} $RELS/2002rels/qrels_${lang}
      mv $RELS/2003rels/qrels_${lang2} $RELS/2003rels/qrels_${lang}
    done

  fi
fi

# Stage 1: Combine Data across years and across folders
# Extract query from sgml file into single line, same as MATERIAL


for lang in "${!L[@]}"; do
  if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  #######################################################
  # Combine Data across years and across folders
  #######################################################

    # Fixing Relevance Files
    if [[ "${processd[@]}" =~ "rel" ]]; then
      echo "Processing rel files..."
      relf=$RELS/all_yrs/qrels_${lang}.txt
      [[ -f $relf ]] && rm $relf

      mkdir -p $RELS/all_yrs
      cat $RELS/{2000,2001,2002,2003}rels/qrels_${lang} > $relf
      # Keep only the rel mappings "1" in 4th column
      awk '{ if ($4==1) {print }}' $relf > $relf.temp

      # The queries from rel file are inconsistent with the query file names. query08 should be
      # query008. We need to reformat the double digit queries to three digits.
      awk '{ if (length($1)==1) {print "query00"$1" "$3} if (length($1)==2) {print "query0"$1" "$3} if (length($1)==3) {print "query"$1" "$3}}' $relf.temp > $relf
      rm $relf.temp

      # Prepare trec eval format
    fi

    # Fixing Docs
    if [[ "${processd[@]}" =~ "doc" ]]; then
#      rm -r ${L[$lang]}
#      cp -r ${L_org[$lang]} $DOCS
#
#      # First, untar all the files 
#      for subdir in `ls -d ${L[$lang]}`; do
#        printf "Untaring $subdir"
#        ls $subdir/*.tgz | xargs -n1 -I % tar -xzf % -C $subdir
#      done
#
#      # Next, fix naming for all files.
#
#      if [ "$lang" == "english" ]; then
#        mkdir -p $DOCS/English_data/la
#        mv $DOCS/English_data/la*.gz $DOCS/English_data/la
#        gunzip $DOCS/English_data/la/*.gz
#        ls -I "*.sgml" $DOCS/English_data/la/*  | xargs -n1 -I % mv % %.sgml
#      fi
#
#      if [ "$lang" == "french" ]; then
#         ls -I "*.dtd" -I "*.sgml" $DOCS/French_data/new_docno/*  | xargs -n1 -I % mv % %.sgml
#         mv $DOCS/French_data/new_docno/lemonde.dtd.sgml $DOCS/French_data/new_docno/lemonde.dtd
#      fi
#
#      if [ "$lang" == "russian" ]; then
#        rename '.xml' '.sgml' $DOCS/Russian_data/xml/*
#      fi
#
#      if [ "$lang" == "german" ]; then
#        rename '.erg' '.sgml' $DOCS/German_data/fr_rundschau/*
#        ls -I "*.dtd" -I "*.sgml" $DOCS/German_data/der_spiegel/* | xargs -n1 -I % mv % %.sgml
#        mv $DOCS/German_data/der_spiegel/derspiegel.dtd.sgml \
#        $DOCS/German_data/der_spiegel/derspiegel.dtd
#      fi
#
      # Next, extract documents from sgml files
#      for subdir in `ls -I 'valid_ids' -I 'README' -I '*.tgz' -I '*.dtd' -I '*_txt' ${L[$lang]}`; do
#        rm_mk ${L[$lang]}/${subdir}_txt
#        echo "Extracting docs from $subdir.."
#        for fil in `ls ${L[$lang]}/${subdir}/*.sgml`; do
#          conv_encoding $fil
#          python src/docparser.py doc ${fil} ${L[$lang]}/${subdir}_txt 
#        done
#      done

      # Copy all documents into specific all_docs folder
      rm_mk ${L[$lang]}/all_docs
      for subdir in `ls -d ${L[$lang]}/*_txt`; do
        cp $subdir/* ${L[$lang]}/all_docs
      done

    fi # end process doc

    # Translate Target Language (German, French, Russian) to English
      # For this we use pre-trained fairseq
      # Note this requires rtx gpus on COE-Grid
    if [[ $translate -eq 1 ]]; then
      #fild=${L[$lang]}/der_spiegel_txt
      #fild=${L[$lang]}/sda95_txt
      fild=${L[$lang]}/fr_rundschau_txt1
      #fild=${L[$lang]}/all_docs
      #fild=${L[$lang]}/xml_txt
      #rm_mk ${fild}_en.tmp
      echo "Translating $lang.."
      python src/translate.py $lang $fild
    fi

    if [[ $merge -eq 1 ]]; then
    # After processing all the files, do a 3way join such that
    # queries must have a valid line in the rels file
    # relevant lines must have a valid query
    # query must have valid document.

      echo "Merging relf, docids, qids"

      relf=$RELS/all_yrs/qrels_${lang}.txt
      query1=$QUERIES/QUERY_english/query_all.txt
      query2=$QUERIES/QUERY_english/query_title.txt
      fild=${L[$lang]}/all_docs_en
#      rm_mk $fild

      [ ! -f $relf ] && echo "Generate $relf first" && exit 1
      [ ! -d $fild.tmp ] && echo "Generate $fild.tmp first" && exit 1

      python src/merge_keys.py "$relf" "$query1" "$fild.tmp" $lang
      python src/merge_keys.py "$relf" "$query2" "$fild.tmp" $lang

      # Prepare trec format
      [[ -f $relf.trec ]] && rm $relf.trec
      awk '{print $1"\tQ0\t"$2"\t1"}' $relf > $relf.trec
#      rm -r $fild.tmp
    fi

  fi # end Stage0


  if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
    printf "\n$lang - STAGE1: Calculating Statistics"

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
  fi # End Stage 1



  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
    printf "\n$lang - STAGE2: Preprocessing"
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
      rm_mk "${bitext1}_tm"
      rm_mk "${bitext2}_tm"
      python src/preprocess.py --mode "tm" --docdir $bitext1 --sw assets/stopwords_en.txt
      python src/preprocess.py --mode "tm" --docdir $bitext2 --sw $stopwordf

    fi

    # Process the Query for Topic Model and for BM25
    if [[ "${processd[@]}" =~ "query" ]]; then
      queryf_all=$QUERIES/QUERY_english/query_all_${lang}.txt
      queryf_title=$QUERIES/QUERY_english/query_title_${lang}.txt

      python src/preprocess.py --mode "tm" --fn $queryf_all --sw assets/stopwords_en.txt 
      python src/preprocess.py --mode "tm" --fn $queryf_title --sw assets/stopwords_en.txt 

      python src/preprocess.py --mode "doc" --fn $queryf_all --sw assets/stopwords_en.txt 
      python src/preprocess.py --mode "doc" --fn $queryf_title --sw assets/stopwords_en.txt 
    fi

    # Process Src Docs for Topic Model and Translated(English) Doc for BM25
    if [[ "${processd[@]}" =~ "doc" ]]; then

      src_docs=${L[$lang]}/all_docs
      rm_mk "${src_docs}_tm"
      python src/preprocess.py --mode "tm" --docdir $src_docs --sw $stopwordf

      en_docs=${L[$lang]}/all_docs_en
      rm_mk ${en_docs}_doc
      python src/preprocess.py --mode "doc" --docdir $en_docs --sw $assets/stopwords_en.txt

    fi
  fi

  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
    printf "\n$lang - STAGE3: train topic model:\n"
    #for k in 10 20 50 100 200 300 400 500; do
    BITEXTD=$BITEXT/DOCS_$lang/build-bitext
    TESTD=${L[$lang]}/all_docs

    #for qtype in all title; do
    for qtype in all; do

      QUERYF=$QUERIES/QUERY_english/query_${qtype}_${lang}.txt.tm
#      for k in 10 20; do
      for k in 10 20 50 100 200 300 400; do
        bash ./bin/runPolyTM.sh train $BITEXTD $lang $k $TESTD $QUERYF
        bash ./bin/runPolyTM.sh infer $BITEXTD $lang $k $TESTD $QUERYF
      done
    done
  fi 


  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
    printf "\n$lang - STAGE4: test topic model:\n"
#    for k in 10 20 50 100 200 300 400 500; do
    #for k in 600 700; do
    mkdir -p results/CLEF

    if [ $baseline -eq 1 ]; then
      suffix=".baseline_tm"
    else
      suffix=""
    fi

    for k in 10; do # take the best TM

      qfn=malletfiles/$lang/QueryTopics.txt.$k
      tfn=malletfiles/$lang/SrcTopics.txt.$k
      relf=$RELS/all_yrs/qrels_${lang}.txt
      resf=results/CLEF/ranking_$lang.txt.tm
      writef=results/CLEF/${lang}_tm_map.txt

      python src/main.py --mode tm --dims $k \
                        --query_fn $qfn --target_fn $tfn --resf $resf

      trec_map "$relf" "$resf" "$k" "${writef}${suffix}" "$lang" "tm" 
    done
  fi # End Stage 4


  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then

    qfn=$QUERIES/QUERY_english/query_title_${lang}.txt.doc
    tfn=${L[$lang]}/all_docs_en_doc
    relf=$RELS/all_yrs/qrels_${lang}.txt
    resf=results/CLEF/ranking_$lang.txt.doc
    writef=results/CLEF/${lang}_doc_map.txt

    python src/main.py --mode doc --dims 0 \
                      --query_fn $qfn --target_fn $tfn --resf $resf

    trec_map "$relf" "$resf" "00" "$writef" "$lang" "doc" 
#    [[ "${processd[@]}" =~ "analysis" ]] && index_query_doc "$lang" "human";
      
#    [[ "${processd[@]}" =~ "mt1" ]] && index_query_doc "$lang" "mt1";
#
#    [[ "${processd[@]}" =~ "mt2" ]] && index_query_doc "$lang" "mt2";
 
  fi # End stage 5

  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then
    for w in 0.01 0.05 0.1 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.5 0.55; do
      python src/combine_models.py $lang $w
      printf "weight $w $lang "
      ./trec_eval/trec_eval -m map data/IRrels_$lang/rels.txt.trec results/combine_$lang.txt
    done

  fi # End Stage 6

done # iterate languages


 
  ####### STAGE 1
  # this script is from print_utils.sh
  #if [ $sstage -le 1 ] && [ $estage -ge 1 ]; then
  #  printf "\n$lang - STAGE1: Calculating Statistics:\n"

  #  if [[ "${processd[@]}" =~ "doc" ]]; then
  #    doc_stats ${L[$lang]}/all_docs
  #  fi

  #  if [[ "${processd[@]}" =~ "query" ]]; then
  #    print_query $QUERIES/QUERY_${lang}/query.txt
  #  fi

  #  if [[ "${processd[@]}" =~ "rel" ]]; then
  ##    print_mapping $RELS/all_yrs/qrels_$lang.txt
  #  fi
  #fi
#  if [ $sstage -le 2 ] && [ $estage -ge 2 ]; then
#  fi
#  if [ $sstage -le 3 ] && [ $estage -ge 3 ]; then
#  if [ $sstage -le 4 ] && [ $estage -ge 4 ]; then
#  if [ $sstage -le 5 ] && [ $estage -ge 5 ]; then
#  if [ $sstage -le 6 ] && [ $estage -ge 6 ]; then



