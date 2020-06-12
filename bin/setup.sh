#!/usr/bin/env bash
VERSION=7.5.0
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$VERSION-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$VERSION-linux-x86_64.tar.gz.sha512
shasum -a 512 -c elasticsearch-$VERSION-linux-x86_64.tar.gz.sha512 
tar -xzf elasticsearch-$VERSION-linux-x86_64.tar.gz
rm elasticsearch*tar.gz*

## Get Treceval
git clone https://github.com/usnistgov/trec_eval.git
cd trec_eval
make


## Get MAllET
git clone https://github.com/mimno/Mallet.git
cd Mallet && ant

# Stopwords from https://github.com/stopwords-iso
# MATERIAL languages
mkdir -p assets
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-so/master/stopwords-so.txt -O \
assets/stopwords_SOMA.txt
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-tl/master/stopwords-tl.txt -O \
assets/stopwords_TAGA.txt
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-sw/master/stopwords-sw.txt -O \
assets/stopwords_SWAH.txt

# German, Russian stopwords (for CLEF)
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-de/master/stopwords-de.txt -O \
  assets/stopwords_german.txt
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-ru/master/stopwords-ru.txt -O \
  assets/stopwords_russian.txt

# Chinese, Arabic stopwords (for Trec)
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-zh/master/stopwords-zh.txt -O \
  assets/stopwords_chinese.txt
wget https://raw.githubusercontent.com/stopwords-iso/stopwords-ar/master/stopwords-ar.txt -O \
  assets/stopwords_arabic.txt

# install fairseq
pip install fairseq
conda install libgcc # we need this for fastBPE
conda install -c anaconda libstdcxx-ng

# get fairseq models
# wmt 19 de-en
wget https://dl.fbaipublicfiles.com/fairseq/models/wmt19.de-en.joined-dict.ensemble.tar.gz
# wmt 19 ru-en
wget https://dl.fbaipublicfiles.com/fairseq/models/wmt19.ru-en.ensemble.tar.gz


# get parallel data 
PARALLELDIR=/home/hltcoe/ssia/parallel_corpora
mkdir -p $PARALLELDIR
wget -P $PARALLELDIR http://data.statmt.org/news-commentary/v14/training/news-commentary-v14.en-ru.tsv.gz
tar zxvf
wget http://data.statmt.org/news-commentary/v14/documents.tgz
