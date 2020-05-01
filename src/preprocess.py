#!/usr/bin/python3
# Author: Suzanna Sia

# Standard imports
import random
import numpy as np
#import pdb
import math
import os, sys
import re
import shutil
import pdb
# argparser
import argparse
from sklearn.datasets import fetch_20newsgroups 
import nltk
import string
# Custom imports

class Pipeline():

    def __init__(self):
        self.vocab = []
        self.nfiles = 0
        self.word_to_file = {}
        self.stopwords = set()
#        self.sent_detector = nltk.data.load('tokenizers/punkt/english.pickle')
        self.data = None
        self.strip_punct = str.maketrans(string.punctuation, " "*len(string.punctuation))
        self.strip_digit = str.maketrans(string.digits, " "*len(string.digits))


    def load_stopwords(self, fpath):
        with open(fpath, 'r', encoding='utf-8') as f:
            self.stopwords = f.readlines()
        self.stopwords = [w.strip() for w in self.stopwords]
        #self.stopwords = set(line.strip() for line in open(fpath))

    def strip_clean(self, text, stopwords=False):

        text = (text.translate(self.strip_punct).translate(self.strip_digit)).lower()
        if stopwords:
            text = [word for word in text.split() if word.strip() not in self.stopwords]
        else:
            text = [word for word in text.split()]

        text = " ".join(text)
        #text = re.sub(r'\s(hyp|syn|evf)\s', ' ', text)
        #text = text.replace("EXAMPLE OF", "")

        return text

    def remove_stopwords(text, self):
        if len(self.stopwords)==0:
            sys.exit('no stopwords found, first do load_stopwords(fpath)')

        keep_words = [word for word in text.split() if word not in self.stopwords]
        return " ".join(keep_words)

def proc_and_save(dir, stopwords=False, mode=""):
    files = os.listdir(dir)
    new_dir = dir+"_proc_"+mode
    
    if os.path.exists(new_dir):
        shutil.rmtree(new_dir)

    if not os.path.exists(new_dir):
        os.mkdir(new_dir)

    for fil in files:
        with open(os.path.join(dir, fil), 'r') as f:
            data = f.readlines()
            data = [pipe.strip_clean(d, stopwords=stopwords) for d in data]
            data = "\n".join(data)
            
            with open(os.path.join(new_dir, fil), 'w') as f:
                f.write(data+"\n")
    print("written to:", new_dir)


if __name__=="__main__":
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--lang', type=str, required=True, choices=['SOMA','TAGA','SWAH'])
    argparser.add_argument('--mode', type=str, required=True, choices=['doc_human', 'doc_mt1',
        'tm', 'doc_mt2'])
    args = argparser.parse_args()
    pipe = Pipeline()


    print(f"Preprocessing for : {args.lang}, {args.mode}")

    if args.mode == "tm":
        dir1 = f'data/DOCS_{args.lang}/build-bitext/eng'
        dir2 = f'data/DOCS_{args.lang}/build-bitext/src'
        dir3 = f'data/DOCS_{args.lang}/ANALYSIS/src'

        pipe.load_stopwords(f'assets/stopwords_en.txt')
        proc_and_save(dir1, stopwords=True, mode=args.mode)

        pipe.load_stopwords(f'assets/stopwords_{args.lang}.txt')
        proc_and_save(dir2, stopwords=True, mode=args.mode)
        proc_and_save(dir3, stopwords=True, mode=args.mode)

        with open(f'data/QUERY_{args.lang}/q.txt.qp', 'r') as f:
            queries = f.readlines()

        queries = [q.strip().lower().split() for q in queries]
        # format for mallet ssngle file input

        # the first token of each line (whitespace delimited, with optional comma) becomes the
        # instance name, the second token becomes the label, and all additional text on the line
        # is interpreted as a sequence of word tokens.

        queries = [q[0]+" Q0 "+" ".join(q[1:]) for q in queries]
        with open(f'data/QUERY_{args.lang}/q.txt.qp.tm', 'w') as f:
            f.write("\n".join(queries)+"\n")


    if "doc" in args.mode:
        mode, system = args.mode.split('_')

        dir1 = f'data/DOCS_{args.lang}/ANALYSIS/src'
        dir2 = f'data/DOCS_{args.lang}/ANALYSIS/{system}_eng'

        proc_and_save(dir1, stopwords=False, mode=mode)
        proc_and_save(dir2, stopwords=False, mode=mode)
