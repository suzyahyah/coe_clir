#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
import numpy as np
import pdb
#import math
import os
import sys
#import argparse

### Third Party imports

### Local/Custom imports

# Comment out debugger before deployment
from debugger import Debugger
DB = Debugger()
DB.debug_mode=False
#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

def vocab_overlap(vocab1, vocab2):

    common_words = set(vocab1).intersection(set(vocab2))
    vocab1_len = len(vocab1)
    vocab2_len = len(vocab2)

    vocab1_prop = len(common_words) / vocab1_len

    print("proportion of words of query in training:", np.around(vocab1_prop, 3))

def material_tm_query_vocab_overlap(lang=""):
    if len(lang)==0:
        sys.exit("must provide language:{SOMA, SWAH, TAGA}")

    # processed files for topic model
    query_fn = f"data/QUERY_{lang}/q.txt.qp.tm"
    with open(query_fn, 'r') as f:
        queries = f.readlines()

    queries = [q.strip().split()[2:] for q in queries]
    query_vocab = []
    for q in queries:
        query_vocab.extend(q)
    query_vocab = set(query_vocab)

    docs_fd = f"data/DOCS_{lang}/build-bitext/eng_proc_tm"
    fns = os.listdir(docs_fd)

    bitext_vocab = set()
    for fn in fns:
        with open(os.path.join(docs_fd, fn), 'r') as f:
            lines = f.readlines()
        
        for line in lines:
            for word in line.split():
                bitext_vocab.add(word)
    
    vocab_overlap(query_vocab, bitext_vocab)
    DB.dp()

if __name__=="__main__":

    lang = sys.argv[1]
    print("Running query vocab diagnostics for :", lang)
    material_tm_query_vocab_overlap(lang=lang)
    print("\n")


    


