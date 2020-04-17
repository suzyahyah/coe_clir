#!/usr/bin/env bash


MALLETDIR=/home/ssia/packages/Mallet
SAVEDIR=malletfiles

# Modify This
SRCTXTDIR=temp/ANALYSIS-$1/text/src
SRCQueryTrain=temp/QUERY_$1.txt.train
SRCQueryValid=temp/QUERY_$1.txt.valid

TransF=$SAVEDIR/$1/topic-input.Mallet
QueryFTrain=$SAVEDIR/$1/topic-query.Mallet.train
QueryFValid=$SAVEDIR/$1/topic-query.Mallet.valid

Inferencer=$SAVEDIR/$1/topic-inferencer
TopicModel=$SAVEDIR/$1/topic-model
TransTopics=$SAVEDIR/$1/TargetTopics.txt

QueryTopicsTrain=$SAVEDIR/$1/QueryTopics.txt.train
QueryTopicsValid=$SAVEDIR/$1/QueryTopics.txt.valid

TopicWords=$SAVEDIR/$1/TopicWords.txt

mkdir -p $SAVEDIR/$1

LANG=$1
NTOPICS=$2

echo "Format Query and Target to mallet.."
$MALLETDIR/bin/mallet import-dir --input $SRCTXTDIR --output $TransF --keep-sequence --remove-stopwords
$MALLETDIR/bin/mallet import-file --input $SRCQueryTrain --output $QueryFTrain --keep-sequence --remove-stopwords
$MALLETDIR/bin/mallet import-file --input $SRCQueryValid --output $QueryFValid --keep-sequence --remove-stopwords

echo "Running Topic Model.."
$MALLETDIR/bin/mallet train-topics --input $TransF --num-topics $NTOPICS --output-doc-topics \
$TransTopics --output-state malletfiles/topic-state.gz --output-model $TopicModel

echo "Convert model to inferencer.."
$MALLETDIR/bin/mallet train-topics --input-model $TopicModel --inferencer-filename $Inferencer --num-iterations 0

#echo "Infer topics from query.."
$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer --input $QueryFTrain --output-doc-topics $QueryTopicsTrain

$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer --input $QueryFValid --output-doc-topics $QueryTopicsValid

#echo "Infer top words from topic.."
#$MALLETDIR/bin/mallet infer-topics --inferencer $Inferencer --input $QueryF --output-topic-keys $TopicWords


echo "done"
