#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
import pandas as pd
import sys
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

names = 'qid q0 docid rank score std'.split()

models='mt1 mt2'.split()
lang =sys.argv[1]
weight = float(sys.argv[2])

dfs = {}
for model in models:
    dfs[model] = pd.read_csv(f'results/ranking_{lang}.txt.{model}', sep="\t", names=names)

merge1 = dfs[models[1]].merge(dfs[models[0]], on=['qid', 'docid'], how="outer",
suffixes=[f'_{models[1]}', f'_{models[0]}'])

for col in merge1.columns:
    merge1[col].fillna(0, inplace=True)


merge1['score'] = (1-weight)*merge1[f'score_{models[1]}']+ weight*merge1[f'score_{models[0]}']
merge1['ranking'] = [1]*len(merge1)

outnames = f'qid q0_{models[1]} docid ranking score std_{models[1]}'.split()
merge1[outnames].to_csv(f'results/combine_{lang}.txt', sep="\t", index=False)



