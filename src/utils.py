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
import json

### Third Party imports

### Local/Custom imports
import preprocess

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

INDEX="coe"
pipe = preprocess.Pipeline()

def docs_to_json(target_doc_fol):
    jsonl = []
    for fil in os.listdir(target_doc_fol):
        dd = {}
        with open(os.path.join(target_doc_fol, fil), 'r') as f:
            text = f.readlines()
            fn = fil[:fil.find('.')]
            dd['_id'] = fn
            dd['doc_text'] = pipe.strip_clean(" ".join(text))
            dd['docid'] = fn
            dd['_index'] = "coe" # refac
        jsonl.append(dd)
    return jsonl

def queries_to_json(queries_doc_fn, strip=False):
    with open(queries_doc_fn, 'r') as f:
        queries = f.readlines()
        queries = [q.strip().split('\t') for q in queries]

    if strip:
        queries = [{'docid':q[0], 'doc_text': pipe.strip_clean(q[1])} for q in queries]
    else:
        queries = [{'docid':q[0], 'doc_text': q[1]} for q in queries]

    return queries



def topics_to_json(fn, query=False):

    with open(fn, 'r') as f:
        data = f.readlines()

    data = data[1:]
    data = [d.strip() for d in data]

    all_json = []
    for d in data:
        d_dict={}
        d = d.split('\t')
        doc_id = d[1].split('/')[-1]
        if '.' in doc_id:
            doc_id = doc_id[:doc_id.find('.')]
        vector = np.array(d[2:]).astype(np.float)

        d_dict['_index'] = INDEX
#        d_dict['_type'] = 'document' # turning this on messes with the indexing
        d_dict['doctopic'] = vector.tolist()
        d_dict['_id'] = doc_id
        d_dict['docid'] = doc_id

        #assert len(d_dict['doctopic'])==10
        all_json.append(d_dict)

    return all_json

def get_query_template(mode=""):

    with open(f'templates/query_{mode}.json', 'r') as f:
        script_query = json.load(f)

    if mode=="doc":
        script_query['query']['simple_query_string']['fields'] = ['doc_text']

    return script_query
