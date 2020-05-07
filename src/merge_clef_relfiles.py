#!/usr/bin/python3
# Author: Suzanna Sia

### Standard imports
#import random
#import numpy as np
#import pdb
#import math
import os
import sys
#import argparse

### Third Party imports

### Local/Custom imports

# Comment out debugger before deployment
#from debugger import Debugger
#DB = Debugger()

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

import pandas as pd
lang = sys.argv[1]
savefn = sys.argv[2]

reldir = "/home/hltcoe/ssia/clef00-03/RelAssess/all_yrs"

lang_df = pd.read_csv(os.path.join(reldir, f'qrels_{lang}.txt'), sep=' ', names=['joinid', 'na', 'docid', 'rel'])
en_df = pd.read_csv(os.path.join(reldir, 'qrels_english.txt'), sep=' ', names=['joinid', 'na', 'docid', 'rel'])

lang_ = lang[0].upper() +lang[1:]

all_en_fn = "/home/hltcoe/ssia/clef00-03/DocumentData/DataCollections/English_data/valid_ids"
all_lang_fn = f"/home/hltcoe/ssia/clef00-03/DocumentData/DataCollections/{lang_}_data/valid_ids"

with open(all_lang_fn, 'r') as f:
    all_lang_ids = f.readlines()
    all_lang_ids = [s.strip().replace('.txt','') for s in all_lang_ids]

with open(all_en_fn, 'r') as f:
    all_en_ids = f.readlines()
    all_en_ids = [s.strip().replace('.txt','') for s in all_en_ids]


en_df = en_df[en_df['docid'].isin(all_en_ids)]
lang_df = lang_df[lang_df['docid'].isin(all_lang_ids)]

merge_df = en_df.merge(lang_df, on="joinid", suffixes=['_en', '_es'])

merge_df[['docid_en', 'docid_es']].to_csv(savefn, index=False, sep=" ", header=False)
print("writing rel file to :", savefn)


