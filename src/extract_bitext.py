#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
#import numpy as np
#import pdb
#import math
#import os
#import sys
#import argparse

### Third Party imports

### Local/Custom imports

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)
import sys

def init():
    bitext_fn = sys.argv[1]

    with open(bitext_fn, 'r') as f:
        data = f.readlines()

    print("num lines:", len(data))
    data = [d.split('\t') for d in data]

    docs = []
    docs_ix = []
    doc = None
    ix = None

    for i, d in enumerate(data):
        if int(d[0].split('_')[1])==1:
            if doc is not None:
                docs.append(doc)
                docs_ix.append(ix)

            doc = [d[1:]]
            ix = [d[0]]

        else:
            doc.append(d[1:])
            ix.append(d[0])

        if i==(len(data)-1):
            docs.append(doc)
            docs_ix.append(ix)

    print("num docs:", len(docs))
    for i, doc in enumerate(docs):
        #if (i % int(len(docs)/100)) ==0:
        #    print(i, "docs processed.")

        src_doc = []
        en_doc = []
        for pair in doc:
            src_doc.append(pair[0].strip())
            en_doc.append(pair[1].strip())

        src_doc = "\n".join(src_doc)
        en_doc = "\n".join(en_doc)

        ix = docs_ix[i][0].split('_')[0]

        with open(f'{sys.argv[2]}/{ix}.txt', 'w') as f:
            f.write(src_doc+"\n")

        with open(f'{sys.argv[3]}/{ix}.txt', 'w') as f:
            f.write(en_doc+"\n") #need to add terminating line or bash will screw up

if __name__ == "__main__":
    init()



