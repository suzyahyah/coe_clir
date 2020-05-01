#!/usr/bin/env bash
# Author: Suzanna Sia

for lang in SOMA TAGA SWAH; do
  python src/diagnostics.py $lang
done

