#!/usr/bin/env bash
# Author: Suzanna Sia

MALLETDIR=/home/ssia/packages/Mallet
SAVEDIR=malletfiles
NTOPICS=$2

SRC_TrainD=temp/DOCS_$1/build-bitext/src_proc_tm
SRC_TrainF=$SAVEDIR/$1/src_format.train

eng_TrainD=temp/DOCS_$1/build-bitext/eng_proc_tm
eng_TrainF=$SAVEDIR/$1/eng_format.train

SRC_TestD=temp/DOCS_$1/ANALYSIS/src_proc_tm
SRC_TestF=$SAVEDIR/$1/src_format.test
SRC_TestTopics=$SAVEDIR/$1/SrcTopics.txt.$2

Query=temp/QUERY_$1/q.txt.qp.tm
QueryF=$SAVEDIR/$1/query_format.test
QueryTopics=$SAVEDIR/$1/QueryTopics.txt.$2

Inferencer=$SAVEDIR/$1/topic-inferencer
TopicModel=$SAVEDIR/$1/topic-model

TopicWords=$SAVEDIR/$1/TopicWords.txt

mkdir -p $SAVEDIR/$1

LANG=$1
NTOPICS=$2

echo "Format Query and Target to mallet.."
$MALLETDIR/bin/mallet import-dir --input $SRC_TrainD --output $SRC_TrainF --keep-sequence --remove-stopwords
$MALLETDIR/bin/mallet import-dir --use-pipe-from $SRC_TrainF --input $SRC_TestD --output $SRC_TestF --keep-sequence --remove-stopwords
$MALLETDIR/bin/mallet import-dir --input $eng_TrainD --output $eng_TrainF --keep-sequence --remove-stopwords
$MALLETDIR/bin/mallet import-file --use-pipe-from $eng_TrainF --input $Query --output $QueryF --keep-sequence --remove-stopwords

echo "Running Polylingual Topic Model.."

$MALLETDIR/bin/mallet run cc.mallet.topics.PolylingualTopicModel --language-inputs $SRC_TrainF $eng_TrainF --num-topics $NTOPICS --alpha 1.0 --inferencer-filename $Inferencer

echo "Infer topics from query and Src Test docs"
$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.0 --input $SRC_TestF --output-doc-topics $SRC_TestTopics

$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer.1 --input $QueryF --output-doc-topics $QueryTopics

#echo "Infer top words from topic.."
#$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer --input $QueryF --output-topic-keys $TopicWords


echo "done"
