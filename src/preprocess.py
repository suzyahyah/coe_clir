#!/usr/bin/python3
# Author: Suzanna Sia

# Standard imports
import random
import numpy as np
import math
import os, sys
import re
import shutil
import pdb
import argparse
import nltk
import string

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

    def strip_clean(self, text, stopwords=False):

        text = (text.translate(self.strip_punct).translate(self.strip_digit)).lower()
        text = [w.strip() for w in text.split() if len(w)>3]

        if stopwords:
            text = [w for w in text if w not in self.stopwords]

        text = " ".join(text)
        return text

    def remove_stopwords(text, self):
        if len(self.stopwords)==0:
            sys.exit('no stopwords found, first do load_stopwords(fpath)')

        keep_words = [word for word in text.split() if word not in self.stopwords]
        return " ".join(keep_words)

def proc_and_save(dir, stopwords=False, mode=""):
    files = os.listdir(dir)
    new_dir = dir+"_"+mode
    
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
    argparser.add_argument('--sw', type=str, required=False)
    argparser.add_argument('--mode', type=str, required=True)
    argparser.add_argument('--docdir', type=str, default=None, required=False)
    argparser.add_argument('--fn', type=str, default=None, required=False)

    args = argparser.parse_args()
    pipe = Pipeline()


    print(f"\nPreprocessing for : {args.fn} {args.docdir}, {args.mode}")

    if args.mode == "tokenize":

        import jieba
        files = os.listdir(args.docdir)
        new_dir = args.docdir+".temp"
        print("tokenizing chinese.")
        for fil in files:
            with open(os.path.join(args.docdir,fil), 'r') as f:
                data = f.readlines()
                data = [jieba.cut_for_search(d) for d in data]
                data = [' '.join(d) for d in data]
                with open(os.path.join(new_dir, fil), 'w') as f:
                    f.write("\n".join(data)+"\n")
        print("written to:", new_dir)


    if args.mode == "tm":
        pipe.load_stopwords(args.sw)
        if args.docdir:
            proc_and_save(args.docdir, stopwords=True, mode=args.mode)

        if args.fn:
            
            with open(args.fn, 'r') as f:
                queries = f.readlines()
            queries = [q.strip().lower().split() for q in queries]
            # format for mallet ssngle file input

            # the first token of each line (whitespace delimited, with optional comma) becomes the
            # instance name, the second token becomes the label, and all additional text on the line
            # is interpreted as a sequence of word tokens.
            queries = [q[0]+" Q0 "+pipe.strip_clean(" ".join(q[1:]), stopwords=True) for q in queries]
            with open(args.fn+".tm", 'w') as f:
                f.write("\n".join(queries)+"\n")


    if "bm25" in args.mode:
        if args.fn:
            with open(args.fn, 'r') as f:
                queries = f.readlines()

            queries = [q.strip().lower().split() for q in queries]
            queries = [q[0]+"\t" + pipe.strip_clean(" ".join(q[1:]), stopwords=False) for q in queries]

            with open(f"{args.fn}.{args.mode}", 'w') as f:
                f.write("\n".join(queries)+"\n")

        elif args.docdir:
            proc_and_save(args.docdir, stopwords=False, mode=args.mode)
