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

lang = sys.argv[1]
fild = sys.argv[2]
newd = fild+"_en"

#os.mkdir(fild+"_en")

if lang == "russian":
    m = "transformer.wmt19.ru-en"

fns = os.listdir(fild)
trans_fns = {}

start = time.time()
print(f"Translating from {lang} to en using {m}")
model = torch.hub.load('pytorch/fairseq', m, tokenizer='moses', bpe='fastbpe', \
        checkpoint_file='model1.pt:model2.pt:model3.pt:model4.pt')
model.cuda()

for i, fn in enumerate(fns):

    if i%10==0:
        print(f"{i} files processed, time elapsed:{start-time.time()}")

    with open(os.path.join(fild, fn), 'r') as f:
        data = f.readlines()
    
    if len(data)==0:
        continue

    data = nltk.sent_tokenize(data[0])
    en_txt = model.translate(data)# [model.translate(line) for line in data]
    
    with open(os.path.join(newd, fn), 'w') as f:
        f.write("\n".join(en_txt)+"\n")

