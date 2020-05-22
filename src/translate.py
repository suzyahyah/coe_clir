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

# Comment out debugger before deployment
#from debugger import Debugger
#DB = Debugger()

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

import torch
import os
import sys
import time
import pdb
import nltk
import re

lang = sys.argv[1]
fild = sys.argv[2]
newd = fild+"_en.tmp"

#os.mkdir(fild+"_en")

if lang == "russian":
    m = "transformer.wmt19.ru-en.single_model"
if lang == "german":
    m = "transformer.wmt19.de-en.single_model"
if lang == "chinese":
    m = "lightconv.glu.wmt17.zh-en"

fns = os.listdir(fild)
trans_fns = {}

start = time.time()
print(f"Translating from {lang} to en using {m}")
#model = torch.hub.load('pytorch/fairseq', m, tokenizer='moses', bpe='fastbpe', \
#        checkpoint_file='model1.pt:model2.pt:model3.pt:model4.pt')
if lang == "chinese":
    model = torch.hub.load('pytorch/fairseq', m, tokenizer='moses', bpe='subword_nmt')
else:
    model = torch.hub.load('pytorch/fairseq', m)

model.eval()
model.cuda()

print("Total number of files:", len(fns))
for i, fn in enumerate(fns):

    if i%10==0:
        print(f"{i} files processed, time elapsed:{time.time()-start}")

    with open(os.path.join(fild, fn), 'r') as f:
        data = f.readlines()
    
    if len(data)==0:
        continue
    
    if lang == "chinese":
        # split chinese into sentences on spacing.
        data = re.sub('([！？。；])', r'\1 ', data[0]).split()
        #data = data[0].split()
    else:
        data = nltk.sent_tokenize(data[0])

    # break up the sentences to avoid OOM errors
    en_txts = []
    while len(data)>0:
        datax = data[:50]

        # Size of sample can only be 1024.
        # Skip sentences longer than 1024 
        if lang == "chinese":
            datax = [d for d in datax if len(d)<200]
        else:
            datax = [d for d in datax if len(d.split())<80]
        try:
            en_txts.extend(model.translate(datax))# [model.translate(line) for line in data]
        except:
            pdb.set_trace()
        data = data[50:]

    with open(os.path.join(newd, fn), 'w') as f:
        f.write("\n".join(en_txts)+"\n")

