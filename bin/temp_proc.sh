#!/usr/bin/env bash
# Author: Suzanna Sia

SRC=/home/hltcoe/ssia/projects/coe_clir/src
GDIR=/home/hltcoe/ssia/clef00-03/DocumentData/DataCollections/German_data
rm -r $GDIR/fr_rundschau_txt
mkdir -p $GDIR/fr_rundschau_txt

for fil in `ls $GDIR/fr_rundschau/*.sgml`; do
  python $SRC/docparser.py doc ${fil} $GDIR/fr_rundschau_txt
done
