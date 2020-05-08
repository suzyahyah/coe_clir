#!/usr/bin/python3
# Author: Suzanna Sia
# Adapted from Sun Shuo
#
### Standard imports
#import random
#import numpy as np
import pdb
#import math
import os
import sys
import re
#import argparse

### Third Party imports

### Local/Custom imports

# Comment out debugger before deployment
from debugger import Debugger
DB = Debugger()

#from distutils.util import str2bool
#argparser = argparser.ArgumentParser()
#argparser.add_argument('--x', type=float, default=0)

from os import path
from collections import defaultdict
from bs4 import BeautifulSoup as bs



def extract_queries(sgml_file, query_dir, year="00"):
    
    with open(sgml_file) as f:
        soup = bs(f.read(), 'html.parser')

    tags = set([tag.name for tag in soup.find_all()])
    tags.remove('num')
    tags.remove('top')

    queries = soup.find_all('top')
    queries_all = []
    for q in queries:
        qid = q.find('num').contents[0].strip()
        qid = qid.replace('C','query')

        if year=="00":
            qtext = q.find_all('num')[0].contents[1].get_text()

        else:
            qtext = []
            for tag in tags:
                if q.find(tag) is not None:
                    qtext.append(q.find(tag).contents[0])

            qtext = " ".join(qtext)
        qtext = " ".join(qtext.split()) #strip out extra lines
        queries_all.append(qid+"\t"+qtext)

    print(f"{len(queries_all)} queries written to {query_dir}")

    queries_all = "\n".join(queries_all)
    with open(os.path.join(query_dir, f'query{year}.txt'), 'w') as f:
        f.write(queries_all + "\n")
    


def parse_write_sgml(sgml_file, txt_dir, rel_fn):
    """Method used to parse sgml files

    Args:
        sgml_file (str): path to sgml file

    Raises:
        Exception: if unable to read tsv file

    """
  
    with open(rel_fn, 'r') as f:
        rels = f.readlines()
    
    rel_files= [d.split()[1] for d in rels]
    print("num rel files:", len(rel_files), rel_fn)


    docd = {}
    with open(sgml_file) as f:
        soup = bs(f.read(), 'html.parser')


    cap = soup.find_all('DOC')
    nocap = soup.find_all('doc')

    if len(cap)==0 and len(nocap)==0:
        sys.exit('Cant handle format')
    
    upperCase=False
    if len(cap)>0:
        upperCase = True
    elif len(nocap)>0:
        lowerCase = True
    
    fmt = {}
    fmt['doc'] = 'doc'
    fmt['docno'] = 'docno'
    fmt['text'] = 'text'
    fmt['stripdocno'] = "<docno>|</docno>"
    fmt['striptext'] = "<text>|</text>"

    if upperCase:
        for k in fmt.keys():
            fmt[k] = fmt[k].upper()

    for doc in soup.find_all(fmt['doc']):
        docnos = doc.find_all(fmt['docno'])

        assert len(docnos)==1
        docno = re.sub(fmt['stripdocno'], "", str(docnos[0])).strip()

        if docno not in rel_files:
            continue

        docd[docno] = []
        texts = doc.find_all(fmt['text'])
        for text in texts:
            text = re.sub(fmt['striptext'], "", str(text))
            text = " ".join(text.split())
            docd[docno].append(text.strip())

        docd[docno] = "\n".join(docd[docno])

    if len(docd.keys())>0:
        for docno in docd.keys():
            write_file = os.path.join(txt_dir, docno) + ".txt"
            with open(write_file, 'w', encoding='utf-8') as f:
                f.write(docd[docno])
        #DB.dp(xcl=['soup', 'doc'])
            
        print(f"wrote {len(docd.keys())} files to folder {txt_dir}")

if __name__=="__main__":

    mode = sys.argv[1]
    fil = sys.argv[2]
    txt_dir = sys.argv[3]

    if mode == "doc":
        rel_fn = sys.argv[4]
        parse_write_sgml(fil, txt_dir, rel_fn)

    elif mode == "query":
        year = str(sys.argv[4])
        extract_queries(fil, txt_dir, year)



