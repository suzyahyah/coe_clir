#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

# This Script prepares Clef Data for Stage 0-7 of the Pipeline

# Stage 0: Make Directories and Prepare Data
# Stage 1: Merge Queries, RelAssess, Docs
# Stage 2: Calculate statistics
# Stage 3: Preprocessing Query and Document
# Stage 4: Train Polylingual Topic Models on BiText
# Stage 5: Test Topic Models
# Stage 6: Index and Retrieve Docs
# Stage 7: Combine Doc Retrieval and TM models

sstage=7 #start stage
estage=7 #end stage
translate=0
reset=0 # if 1, remove and copy all directories. We rarely want to do this.
baseline=0
query_english_only=1 # if 0, extracts other language queries.

processd=(doc)

# Original Data Directory
DIR0003_org=/home/hltcoe/kduh/data/ir/clef00-03
DIR0304_org=/home/hltcoe/kduh/data/ir/clef03-04

# New Save Directory
DIR0003=/home/hltcoe/ssia/clef00-03
DIR0304=/home/hltcoe/ssia/clef03-04

DOCS=$DIR0003/DocumentData/DataCollections
DOCS_org=$DIR0003_org/DocumentData/DataCollections

RELS=$DIR0003/RelAssess
QUERIES=$DIR0003/Topics
BITEXT=/home/hltcoe/ssia/parallel_corpora/split

# Temp for Sun shuo
#declare -A Q=(
#['dutch']=Top-nl
#['english']=Top-en
#['finnish']=Top-fi
#['french']=Top-fr
#['german']=Top-de
#['italian']=Top-it
#['russian']=Top-ru
#['spanish']=Top-es
#['swedish']=Top-sv
#['chinese']=Top-zh
#['japanese']=Top-ja
#['portugese']=Top-pt
#)

declare -A L=(
#['amaryllis']=${DOCS}/Amaryllis_data
#['dutch']=${DOCS}/Dutch_data
#['english']=${DOCS}/English_data
#['finnish']=${DOCS}/Finnish_data
#['french']=${DOCS}/French_data
['german']=${DOCS}/German_data
#['italian']=${DOCS}/Italian_data
#['russian']=${DOCS}/Russian_data
#['spanish']=${DOCS}/Spanish_data
#['swedish']=${DOCS}/Swedish_data
)

declare -A L_org=(
#['amaryllis']=${DOCS_org}/Amaryllis_data
#['dutch']=${DOCS_org}/Dutch_data
#['english']=${DOCS_org}/English_data
#['finnish']=${DOCS_org}/Finnish_data
#['french']=${DOCS_org}/French_data
#['german']=${DOCS_org}/German_data
#['italian']=${DOCS_org}/Italian_data
['russian']=${DOCS_org}/Russian_data
#['spanish']=${DOCS_org}/Spanish_data
#['swedish']=${DOCS_org}/Swedish_data
)

# removing and copy entire directories
# we rarely want to do this cos it takes forever
#if [ $reset -eq 1 ]; then
#  [ -d $DIR0003 ] && rm -r $DIR0003
#  [ -d $DIR0304 ] && rm -r $DIR0304
#  cp -r $DIR0003_org $DIR0003
#  cp -r $DIR0304_org $DIR0304
#fi


# Stage 0: Get Data
if [ $sstage -le 0 ] && [ $estage -ge 0 ]; then
  
  ###########################################
  # Process Queries
  ###########################################

  # Folder and file renaming for consistency    
  if [[ "${processd[@]}" =~ "query" ]]; then
    if [ $reset -eq 1 ]; then
      [ -d $DIR0003/Topics ] && rm -r $DIR0003/Topics
      cp -r $DIR0003_org/Topics $DIR0003
    fi

    tfil=$DIR0003/Topics/topics2000
    cp $tfil/TOP-G.txt $tfil/Top-de00.txt
    cp $tfil/TOP-E.txt $tfil/Top-en00.txt
    cp $tfil/TOP-SP.txt $tfil/Top-es00.txt
    cp $tfil/TOP-FI.txt $tfil/Top-fi00.txt
    cp $tfil/TOP-D.txt $tfil/Top-nl00.txt
    cp $tfil/TOP-F.txt $tfil/Top-fr00.txt
    cp $tfil/TOP-I.txt $tfil/Top-it00.txt
    cp $tfil/TOP-SW.txt $tfil/Top-sv00.txt

    tfil=$DIR0003/Topics/topics2001
    cp $tfil/TOP-ZH01.TXT $tfil/Top-zh01.txt

    tfil=$DIR0003/Topics/topics2002
    cp $tfil/Top-fi50-02.txt $tfil/Top-fi02.txt
    cp $tfil/Top-ja02-utf8.txt $tfil/Top-ja02.txt
    cp $tfil/Top-zh02.unicode $tfil/Top-zh02.txt

    tfil=$DIR0003/Topics/topics2003
    cp $tfil/japan/top-ja03-utf8.utf8 $tfil/Top-ja03.txt
    cp $fil/Top-zh03-utf8.txt $fil/Top-zh03.txt

    # mv 2004 English and Russian queries
    mkdir -p $DIR0003/Topics/topics2004
    cp $DIR0304/Top-en04.txt $DIR0003/Topics/topics2004/Top-en04.txt
    cp $DIR0304/Top-ru04.txt $DIR0003/Topics/topics2004/Top-ru04.txt


#    The python script src/docparser.py extracts queries and constructs 2 versions:
#    Extract query from sgml file into single line, same as MATERIAL
#    (1) title only 'query_title.txt',
#    (2) query description, and narrative 'query_all.txt'

#     Original Query files are in Topics/topics{2000,..2003}
#     Extracted queries are in QUERY_${lang}
#     Sanity Check: 200 lines each in QUERY_${lang}/query_{title,all}.txt

    #######################################################
    # Extract English Queries only
    #######################################################
    
    if [ $query_english_only -eq 1 ]; then
      Q_eng=$QUERIES/QUERY_english
      if [ $reset -eq 1 ]; then
        rm_mk $Q_eng
      fi

      for yr in 00 01 02 03 04; do #2000 is broken
        fil=$QUERIES/topics20${yr}/Top-en${yr}.txt
        conv_encoding $fil
        python src/docparser.py query $fil $Q_eng $yr
      done
      cat $Q_eng/query{00,01,02,03,04}_title.txt > $Q_eng/query_title.txt
      cat $Q_eng/query{00,01,02,03,04}_all.txt > $Q_eng/query_all.txt
    else

      #######################################################
      # Extract all language queries
      #######################################################
      for lang in "${!Q[@]}"; do
        Q_lang = $QUERIES/QUERY_${lang}
        rm_mk $Q_lang
        for yr in 00 01 02 03 04; do #2000 is broken
          fil=$QUERIES/topics20${yr}/${Q[$lang]}$yr.txt
          conv_encoding $fil
          python src/docparser.py query $fil $Q_lang $yr
        done
        cat $Q_lang/query{00,01,02,03,04}_title.txt > $Q_lang/query_title.txt
      done
    fi
  fi

    #######################################################
    # Extract relevance assessments
    #######################################################
  if [[ "${processd[@]}" =~ "rels" ]]; then
#    [ -d $DIR0003/RelAssess ] && rm -r $DIR0003/RelAssess
#    cp -r $DIR0003_org/RelAssess $DIR0003

    # renaming stuff
    mkdir -p $RELS/2004rels
    mv $RELS/2000rels/biling_qrels $RELS/2000rels/qrels_english
    mv $RELS/2001rels/qrels_bilingual $RELS/2001rels/qrels_english
    mv $DIR0304/qrels_ru_2004 $RELS/2004rels/qrels_russian

    for lang in "${!L[@]}"; do
      mv $RELS/2000rels/${lang}_qrels $RELS/2000rels/qrels_${lang}
      lang2=`conv_lang $lang`
      mv $RELS/2002rels/qrels_${lang2} $RELS/2002rels/qrels_${lang}
      mv $RELS/2003rels/qrels_${lang2} $RELS/2003rels/qrels_${lang}
    done

    # Preparing relevance files
    # - Combine across years
    # - keep only mappings "1"
    # - Reformat 

    for lang in "${!L[@]}"; do
      relf=$RELS/all_yrs/qrels_${lang}.txt
      echo "Processing rel files from 00-03... to $relf"
      [[ -f $relf ]] && rm $relf

      mkdir -p $RELS/all_yrs
      cat $RELS/{2000,2001,2002,2003,2004}rels/qrels_${lang} > $relf
      # Keep only the rel mappings "1" in 4th column
      awk '{ if ($4==1) {print }}' $relf > $relf.temp

      # The queries from rel file are inconsistent with the query file names. query08 should be
      # query008. We need to reformat the double digit queries to three digits.
      awk '{ if (length($1)==1) {print "query00"$1" "$3} if (length($1)==2) {print "query0"$1" "$3} if (length($1)==3) {print "query"$1" "$3}}' $relf.temp > $relf
      rm $relf.temp
     # temporary for Sunshuo
#      rm_mk $RELS/qrels_${lang}
#      for year in 2000 2001 2002 2003; do
#        awk '{ if ($4==1) {print }}' $RELS/${year}rels/qrels_${lang} > $RELS/qrels_${lang}/${year}.txt
#      done
    done
  fi

  #######################################################
  # Extract and Combine Documents across years and across folders
  #######################################################

  if [[ "${processd[@]}" =~ "doc" ]]; then
    for lang in "${!L[@]}"; do
    # Uncomment to reset entire directory ; Note that we will lose the translations
    #  [[ -d ${L[$lang]} ]] && rm -r ${L[$lang]}
    #  cp -r ${L_org[$lang]} $DOCS
#
#     First, untar all the files 
      for subdir in `ls -d ${L[$lang]}`; do
        printf "Untaring $subdir\n"
        ls $subdir/*.tgz | xargs -n1 -I % tar -xzf % -C $subdir
      done

#     Fix naming for all files.
      if [ "$lang" == "english" ]; then
        mkdir -p $DOCS/English_data/la
        mv $DOCS/English_data/la*.gz $DOCS/English_data/la
        gunzip $DOCS/English_data/la/*.gz
        ls -I "*.sgml" $DOCS/English_data/la/*  | xargs -n1 -I % mv % %.sgml
      fi

#     Extract documents from sgml files
      for subdir in `ls -I 'valid_ids' -I 'all_docs' -I 'README' -I '*.tgz' -I '*.dtd' -I '*_txt' ${L[$lang]}`; do
        rm_mk ${L[$lang]}/${subdir}_txt
        echo "Extracting docs from $subdir.."

        for fil in `ls ${L[$lang]}/${subdir}/*`; do
          fname=$(basename $fil)
          if [[ "$fname" =~ .*"README".* ]] || [[ "$fname" =~ .*".dtd" ]]; then
            true
          else
            conv_encoding $fil
            python src/docparser.py doc ${fil} ${L[$lang]}/${subdir}_txt 
          fi
        done # end docparse.py file
      done # end directory
    done # end langs
  fi # end process doc


  #######################################################
  # Translate Documents
  #######################################################
  if [[ $translate -eq 1 ]]; then
    # Translate Target Language to English
    # Languages supported: German, French, Russian
    # Modify src/translate.py if the translation system changes.

    # For this we use pre-trained fairseq
    # Note this requires rtx gpus on COE-Grid

    # Translate a specific folder manually or everything ending with {name}_txt
    # The new documents will be in {name}_txt_en

    for lang in "${!L[@]}"; do
      fild=${L[$lang]}/der_spiegel_txt
      mkdir -p ${fild}_en
      #fild=${L[$lang]}/all_docs
      #fild=${L[$lang]}/xml_txt
      #rm_mk ${fild}_en.tmp
      echo "Translating $lang.."
      python src/translate.py $lang $fild
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
    echo "Removing and Copying $subdir to all_docs_en.. this could take a while."
    rm_mk ${L[$lang]}/all_docs_en
    for subdir in `ls -d ${L[$lang]}/*_txt_en`; do
      cp -l $subdir/* ${L[$lang]}/all_docs_en
    done

    #echo "Removing and copying $subdir to all_docs_src.. this could take a while."
    #rm_mk ${L[$lang]}/all_docs_src
    #for subdir in `ls -d ${L[$lang]}/*_txt`; do
    #  cp -l $subdir/* ${L[$lang]}/all_docs_src
    #done

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

      en_docs=${L[$lang]}/all_docs_en
      rm_mk ${en_docs}_bm25
      python src/preprocess.py --mode "bm25" --docdir $en_docs 
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

    #for qtype in all title; do
    for qtype in all title; do
      QUERYF=$QUERIES/QUERY_english/query_${qtype}_${lang}.txt.tm
#      for k in 10 20; do
      #for k in 10 20 50 100 200 300 400; do
      for k in 20 50 100 200; do
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
    mkdir -p results/CLEF/$lang

    if [ $baseline -eq 1 ]; then
      suffix=".baseline_tm"
    else
      suffix=""
    fi

    for qtype in title all; do
      writef=results/CLEF/$lang/tm.$qtype.map
      [[ -f $writef ]] && rm $writef
      echo "lang\tmodel\ttopics\tscore\n" > $writef

      for k in 20 50 100 200; do # take the best TM
      #for k in 20; do # take the best TM

        qfn=malletfiles/$lang/query_$qtype.$k
        tfn=malletfiles/$lang/SrcTopics.$k

        relf=$RELS/all_yrs/qrels_${lang}.txt

        resf=results/CLEF/$lang/tm.$qtype.ranking.$k

        [[ ! -f $qfn ]] && echo "$qfn does not exist, run infererence from stage4" && exit 1
        [[ ! -f $tfn ]] && echo "$tfn does not exist, run infererence from stage4" && exit 1
        [[ ! -f $relf ]] && echo "$relf does not exist, run stage0-1" && exit 1
        echo "Stage 5: Testing topic model retrieval $lang ${k} topics with query ${qtype}"
        python src/main.py --mode tm --dims $k \
                          --query_fn $qfn --target_fn $tfn --resf $resf

        trec_map "$relf" "$resf" "$k" "${writef}${suffix}" "$lang" "tm-${qtype}" 
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

      writef=results/CLEF/$lang/bm25.$qtype.map
      [[ -f $writef ]] && rm $writef
      echo "lang\tmodel\ttopics\tscore\n" > $writef


      qfn=$QUERIES/QUERY_english/query_${qtype}_${lang}.txt.bm25
      tfn=${L[$lang]}/all_docs_en_bm25
      relf=$RELS/all_yrs/qrels_${lang}.txt
      resf=results/CLEF/$lang/bm25.${qtype}.ranking

      python src/main.py --mode doc --dims 0 \
                        --query_fn $qfn --target_fn $tfn --resf $resf

      trec_map "$relf" "$resf" "00" "$writef" "$lang" "doc-${qtype}" 
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
      outf=results/CLEF/${lang}/combine.$qtype

      [[ -f $outf.map ]] && rm $outf.map && rm $outf.ranking && $outf.ranking.tmp
      echo "lang\tmodel\ttopics\tscore\n" > $outf.map

      maxk=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k}' results/CLEF/$lang/tm.$qtype.map`
      echo "querytype:$qtype, max topic:$maxk" 

      tmrank=results/CLEF/${lang}/tm.${qtype}.ranking.$maxk
      docrank=results/CLEF/${lang}/bm25.${qtype}.ranking

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




