#!/usr/bin/python3
# Author: Suzanna Sia

import torch
import os
import sys
import time
import nltk
import re
import numpy as np

def translate(lang, fild, m):
    newd = fild+"_en"
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
    try:
        model.cuda()
    except:
        raise RuntimeError("Not using cuda/GPU. Please enable this or it will take extremely long to translate.")

    print("Total number of files:", len(fns))
    for i, fn in enumerate(fns):
        if i% int(len(fns)/10) == 0:
            print(f"{i}/{len(fns)} files processed, time elapsed:{np.around(time.time()-start,5)}")

        with open(os.path.join(fild, fn), 'r') as f:
            data = f.readlines()
        
        if len(data)==0:
            continue
        
        if lang == "chinese":
            # split chinese into sentences on spacing.
            data = re.sub('([！？。；])', r'\1 ', data[0]).split()
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

            en_txts.extend(model.translate(datax))# [model.translate(line) for line in data]
            data = data[50:]

        with open(os.path.join(newd, fn), 'w') as f:
            f.write("\n".join(en_txts)+"\n")

if __name__ == "__main__":

    lang = sys.argv[1]
    fild = sys.argv[2]

    if lang == "russian":
        m = "transformer.wmt19.ru-en.single_model"
    elif lang == "german":
        m = "transformer.wmt19.de-en.single_model"
    elif lang == "chinese":
        m = "lightconv.glu.wmt17.zh-en"
    else:
        raise ValueError(f"{lang} is not supported . Only 'russian', 'german', and 'chinese' \
        are currently supported.")

    translate(lang, fild, m)

