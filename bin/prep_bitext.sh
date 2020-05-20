#!/usr/bin/env bash
# Author: Suzanna Sia

source ./bin/utils.sh

# This Script prepares bitext which can be used for both CLEF and TREC
declare -A L
NEWSC=/home/hltcoe/ssia/parallel_corpora/split

L=(
['english']=${NEWSC}/en
#['french']=${NEWSC}/fr
['german']=${NEWSC}/de
#['russian']=${NEWSC}/ru
)

# Find all matching names
for lang in "${!L[@]}"; do

  if [[ $lang != "english" ]]; then
    rm_mk $NEWSC/DOCS_$lang/build-bitext/src
    rm_mk $NEWSC/DOCS_$lang/build-bitext/eng

    fns=`comm -12 <(ls ${L[english]}) <(ls ${L[$lang]})`
    echo "Building bitext for $lang .." 
    for fn in $fns; do
      cp ${L[english]}/$fn $NEWSC/DOCS_$lang/build-bitext/src/$fn
      cp ${L[$lang]}/$fn $NEWSC/DOCS_$lang/build-bitext/eng/$fn
    done
    echo "done"
  fi
done
