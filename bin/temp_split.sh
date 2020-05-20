#!/usr/bin/env bash
# Author: Suzanna Sia

files_per_dir=100000
dirx=split_all_docs
n=0
N=0

for filn in `ls all_docs_backup`; do
  if [ "$(( n % files_per_dir))" -eq 0 ]; then
    N=$(( N + 1 ))
    dir="${dirx}_${N}"
    mkdir -p $dir
  fi

  n=$(( n + 1 ))
  mv all_docs_backup/$filn $dir
done
