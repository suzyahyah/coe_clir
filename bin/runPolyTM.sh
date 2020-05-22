#!/usr/bin/env bash
# Author: Suzanna Sia

#MALLETDIR=/home/ssia/packages/Mallet
MALLETDIR=Mallet
SAVEDIR=malletfiles


BITEXTDIR=$2
LANG=$3
NTOPICS=$4
TESTDIR=$5
QUERYF=$6

[[ ! -d $MALLETDIR ]] && "Install Mallet first" && exit 1
mkdir -p $SAVEDIR/$LANG

#SRC_TrainD=temp/DOCS_$1/build-bitext/src_tm
SRC_TrainD=$BITEXTDIR/src_tm
SRC_TrainF=$SAVEDIR/$LANG/src_format.train

eng_TrainD=$BITEXTDIR/eng_tm
eng_TrainF=$SAVEDIR/$LANG/eng_format.train

SRC_TestD=${TESTDIR}_tm
SRC_TestF=$SAVEDIR/$LANG/src_format.test
SRC_TestTopics=$SAVEDIR/$LANG/SrcTopics.txt.$NTOPICS

Query=$QUERYF
QB=`basename $Query`
QueryF=$SAVEDIR/$LANG/$QB.test
QueryTopics=$SAVEDIR/$LANG/QueryTopics.txt.$NTOPICS

Inferencer=$SAVEDIR/$LANG/topic-inferencer
TopicModel=$SAVEDIR/$LANG/topic-model

TopicWords=$SAVEDIR/$LANG/TopicWords.txt

if [[ "$1" == "train" ]]; then
  echo "Training Polylingual Topic Model.."
  $MALLETDIR/bin/mallet import-dir --input $SRC_TrainD --output $SRC_TrainF --keep-sequence
  $MALLETDIR/bin/mallet import-dir --input $eng_TrainD --output $eng_TrainF --keep-sequence 
  $MALLETDIR/bin/mallet run cc.mallet.topics.PolylingualTopicModel --language-inputs $SRC_TrainF $eng_TrainF --num-topics $NTOPICS --alpha 1.0 --inferencer-filename $Inferencer.k$NTOPICS
fi

if [[ "$1" == "infer" ]]; then
  echo "Infer topics from query and Src Test docs"
  $MALLETDIR/bin/mallet import-dir --use-pipe-from $SRC_TrainF --input $SRC_TestD --output $SRC_TestF --keep-sequence 
  $MALLETDIR/bin/mallet import-file --use-pipe-from $eng_TrainF --input $Query --output $QueryF --keep-sequence
  $MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.0 --input $SRC_TestF --output-doc-topics $SRC_TestTopics
  $MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.1 --input $QueryF --output-doc-topics $QueryTopics
fi

#echo "Format Query and Target to mallet.."

#[[ ! -f $SRC_TrainF ]] && $MALLETDIR/bin/mallet import-dir --input $SRC_TrainD --output $SRC_TrainF --keep-sequence
#[[ ! -f $SRC_TestF ]] && $MALLETDIR/bin/mallet import-dir --use-pipe-from $SRC_TrainF --input $SRC_TestD --output $SRC_TestF --keep-sequence 

#[[ ! -f $eng_TrainF ]] && $MALLETDIR/bin/mallet import-dir --input $eng_TrainD --output $eng_TrainF --keep-sequence 

#[[ ! -f $QueryF ]] && $MALLETDIR/bin/mallet import-file --use-pipe-from $eng_TrainF --input $Query --output $QueryF --keep-sequence

#[[ ! -f $Inferencer.k$NTOPICS.0 ]] && $MALLETDIR/bin/mallet run cc.mallet.topics.PolylingualTopicModel --language-inputs $SRC_TrainF $eng_TrainF --num-topics $NTOPICS --alpha 1.0 --inferencer-filename $Inferencer.k$NTOPICS

#echo "Infer topics from query and Src Test docs"
#[[ ! -f $SRC_TestTopics ]] && $MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.0 --input $SRC_TestF --output-doc-topics $SRC_TestTopics

#$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.1 --input $QueryF --output-doc-topics $QueryTopics


# Deprecate
#echo "Infer top words from topic.."
#$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer --input $QueryF --output-topic-keys $TopicWords


echo "done"
