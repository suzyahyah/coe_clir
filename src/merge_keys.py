#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
#import numpy as np
import pdb
#import math
import os
import sys
import shutil
#import argparse

### Third Party imports
import pandas as pd

### Local/Custom imports

# Comment out debugger before deployment
#from debugger import Debugger
#DB = Debugger()

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

"""
Script for merging docids and queryids across three files:
    1. relevant file (queryid, docid)
    2. query file (queryid, query)
    3. document folder (just the folder)

Only keep queries which exist in the relevance file. 
Only keep documents which exist in the relevance file.
Only keep relevance pairs if they exist in the queryfile and document folder.
Accomplished with a three way inner join.

"""
def init():

    rel_f = sys.argv[1]
    query_f = sys.argv[2]
    doc_fold = sys.argv[3]

    if len(sys.argv)==5:
        suffix = "_"+sys.argv[4]
    else:
        suffix=""

    # Setting up dataframes
    rel_df = pd.read_csv(rel_f, names=['qid', 'docid'], sep="\s+")
    q_df = pd.read_csv(query_f, names=['qid', 'q'], sep="\t")

    doc_fns = os.listdir(doc_fold)
    doc_df = pd.DataFrame(doc_fns, columns=['docid_sfx'])
    doc_df['docid'] = doc_df['docid_sfx'].apply(lambda x: x[:x.find('.')]) # strip suffix

    # three-way inner join
    merge_df = rel_df.merge(q_df, on='qid', how='inner').merge(doc_df, on='docid', how='inner')

    # extract the queries, docs, and relevance dataframes
    q_new = merge_df[['qid', 'q']].drop_duplicates()
    doc_new = merge_df[['docid', 'docid_sfx']].drop_duplicates()
    rel_new = merge_df[['qid', 'docid']].drop_duplicates()

    if len(q_new)==0:
        sys.exit("0 queries - something went wrong in merge")
    elif len(rel_new) == 0:
        sys.exit("0 rels - something weng wrong in merge")


    # write to file
    # clean up names
    relfn = rel_f[:rel_f.find('.')] + ".txt"
    qfn = query_f[:query_f.find('.')] + suffix +".txt"

    rel_new.to_csv(relfn, index=False, header=False, sep="\t")
    q_new.to_csv(qfn, index=False, header=False, sep="\t")

    print("New queries written to:", qfn)
    print("New relfiles written to:", relfn)
#
#    # copy relevant documents over to new folder
#    #new_folder = doc_fold[:doc_fold.find('.')]
#
#    if os.path.isdir(new_folder):
#        shutil.rmtree(new_folder)
#        os.mkdir(new_folder)
#
#    for fn in doc_new['docid_sfx'].values:
#        old_fn = os.path.join(doc_fold, fn)
#        new_fn = os.path.join(new_folder, fn)
#        shutil.copy(old_fn, new_fn)
#
#    # save valid qids
#    qids = list(q_new['qid'].values)
#    query_fold = os.path.dirname(query_f)
#    with open(os.path.join(query_fold, 'valid_qids'), 'w') as f:
#        f.write("\n".join(qids))


    # save valid docids one level up
#    docids = list(doc_new['docid'].values)
#    with open(os.path.join(doc_fold, '..', 'valid_docids'), 'w') as f:
#        f.write("\n".join(docids))
#

if __name__ == "__main__":
    init()



