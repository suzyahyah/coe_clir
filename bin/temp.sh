#!/usr/bin/env bash
# Author: Suzanna Sia
source ./bin/utils.sh

for fil in `ls /home/hltcoe/ssia/clef00-03/DocumentData/DataCollections/German_data/der_spiegel/*`; do
  fname=$(basename $fil)
  conv_encoding $fil
  python src/docparser.py doc ${fil} /home/hltcoe/ssia/clef00-03/DocumentData/DataCollections/German_data/der_spiegel_txt
done

