#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
import pandas as pd
import sys
#import numpy as np
import pdb
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

def init():
    names = 'qid q0 docid rank score std'.split()
    #models='mt1 mt2'.split()

    #lang =sys.argv[1]
    weight = float(sys.argv[1])
    ranking1 = sys.argv[2]
    ranking2 = sys.argv[3]
    outf = sys.argv[4]

    dfs = []
    dfs.append(pd.read_csv(ranking1, sep="\t", names=names))
    dfs.append(pd.read_csv(ranking2, sep="\t", names=names))
    
    merge1 = dfs[0].merge(dfs[1], on=['qid', 'docid'], how="outer", suffixes=['_1', '_2'])
#    print(len(dfs[0]), len(dfs[1]), len(merge1))

    for col in merge1.columns:
        merge1[col].fillna(0, inplace=True)


    merge1['score'] = (1-weight)*merge1[f'score_1']+ weight*merge1[f'score_2']
    merge1['ranking'] = [1]*len(merge1)

    outnames = f'qid q0_1 docid ranking score std_1'.split()
    merge1[outnames].to_csv(outf, sep="\t", index=False)

if __name__ == "__main__":
    init()


