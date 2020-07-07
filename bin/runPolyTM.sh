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
QTYPE=$7

[[ -d $MALLETDIR/bin ]] || { echo "Install Mallet first or Set Mallet Directory in bin/runPolyTM.sh" && exit 1; }
#

mkdir -p $SAVEDIR/$LANG

### Used both during training and inference
SRC_TrainD=$BITEXTDIR/src_tm
SRC_TrainF=$SAVEDIR/$LANG/src_format.train

eng_TrainD=$BITEXTDIR/eng_tm
eng_TrainF=$SAVEDIR/$LANG/eng_format.train

Inferencer=$SAVEDIR/$LANG/topic-inferencer
TopicModel=$SAVEDIR/$LANG/topic-model


if [[ "$1" == "train" ]]; then
  if [ -f $Inferencer.k$NTOPICS.0 ]; then
    echo "k$NTOPICS Already trained"
  else
    echo "Training Polylingual Topic Model.. k$NTOPICS"
    $MALLETDIR/bin/mallet import-dir --input $SRC_TrainD --output $SRC_TrainF --keep-sequence
    $MALLETDIR/bin/mallet import-dir --input $eng_TrainD --output $eng_TrainF --keep-sequence

    $MALLETDIR/bin/mallet run cc.mallet.topics.PolylingualTopicModel --language-inputs $SRC_TrainF $eng_TrainF --num-topics $NTOPICS --alpha 1.0 --inferencer-filename $Inferencer.k$NTOPICS
  fi
fi

if [[ "$1" == "infer" ]]; then

  Query=$QUERYF
  QB=$(basename $Query)
  QueryF=$SAVEDIR/$LANG/$QB.test
  QueryTopics=$SAVEDIR/$LANG/query_$QTYPE.$NTOPICS
  SRC_TestD=${TESTDIR}_tm
  SRC_TestF=$SAVEDIR/$LANG/src_format.test
  SRC_TestTopics=$SAVEDIR/$LANG/SrcTopics.$NTOPICS


  [[ ! -f $Inferencer.k$NTOPICS.0 ]] && echo "Error: Train topic model first." && exit 1

  [[ ! -f $SRC_TrainF ]] && $MALLETDIR/bin/mallet import-dir --input $SRC_TrainD --output $SRC_TrainF --keep-sequence
  [[ ! -f $eng_TrainF ]] && $MALLETDIR/bin/mallet import-dir --input $eng_TrainD --output $eng_TrainF --keep-sequence

  [[ ! -f $SRC_TestF ]] && $MALLETDIR/bin/mallet import-dir --use-pipe-from $SRC_TrainF --input $SRC_TestD --output $SRC_TestF --keep-sequence

  [[ ! -f $QueryF ]] && $MALLETDIR/bin/mallet import-file --use-pipe-from $eng_TrainF --input $Query --output $QueryF --keep-sequence

  [[ ! -f $SRC_TestTopics ]] && echo "Infering $NTOPICS topics for $SRC_TestTopics" && $MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.0 --input $SRC_TestF --output-doc-topics $SRC_TestTopics

  [[ ! -f $QueryTopics ]] && echo "Infering $NTOPICS topics for $QueryTopics" && $MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.k$NTOPICS.1 --input $QueryF --output-doc-topics $QueryTopics
fi

