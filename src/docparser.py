#!/usr/bin/python3
# Author: Suzanna Sia
# Adapted from Sun Shuo
#
### Standard imports
import pdb
import os
import sys
import re
from os import path

from collections import defaultdict
from bs4 import BeautifulSoup as bs


def extract_queries(sgml_file, write_dir, year="", dformat=""):
    
    with open(sgml_file) as f:
        soup = bs(f.read(), 'html.parser')

    tags = set([tag.name for tag in soup.find_all()])
    tags.remove('num')
    tags.remove('top')

    queries = soup.find_all('top')
    queries_all = []
    queries_title = []

    if dformat=="trec":
        rep = "Number: CH"
    else:
        rep = "C"


    for qry in queries:
        qid = qry.find('num').contents[0].strip()
        qid = qid.replace(rep,'query')

        if year=="00":
            qtext = qry.find_all('num')[0].contents[1]
            title = qtext.contents[0].strip()
            alltext = qtext.get_text()

        else:
            alltext = []
            title = ""

            for tag in tags:
                if qry.find(tag) is not None and "c-" not in tag:
                    alltext.append(qry.find(tag).contents[0])

                    if "title" in tag:
                        title = qry.find(tag).contents[0].strip()

            alltext = " ".join(alltext)

        alltext = " ".join(alltext.split()) #strip out extra lines

        assert len(title)!=0 and len(alltext)!=0

        queries_all.append(qid+"\t"+alltext)
        queries_title.append(qid+"\t"+title)


    q_allfp = os.path.join(write_dir, f'query{year}_all.txt')
    q_titlefp = os.path.join(write_dir, f'query{year}_title.txt')

    print(f"{len(queries_all)} queries written to {q_allfp}")
    print(f"{len(queries_title)} queries written to {q_titlefp}")


    queries_all = "\n".join(queries_all)
    with open(q_allfp, 'w') as f:
        f.write(queries_all + "\n")
    
    queries_title = "\n".join(queries_title)
    with open(q_titlefp, 'w') as f:
        f.write(queries_title + "\n")

def parse_write_sgml(sgml_file, write_dir):
    """Method used to parse sgml files

    Args:
        sgml_file (str): path to sgml file

    Raises:
        Exception: if unable to read tsv file

    """
    
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
    fmt['text2'] = 'tx'
    fmt['text3'] = "body"
    fmt['stripdocno'] = "<docno>|</docno>"
    fmt['striptext'] = "<text>|</text>"

    if upperCase:
        for k in fmt.keys():
            fmt[k] = fmt[k].upper()


    for doc in soup.find_all(fmt['doc']):
        docnos = doc.find_all(fmt['docno'])

        assert len(docnos)==1
        docno = re.sub(fmt['stripdocno'], "", str(docnos[0])).strip()

        # Different file formatting
        # refactor this ugly thing
        texts = doc.find_all(fmt['text'])
        if len(texts)==0:
            texts = doc.find_all(fmt['text2'])
            if len(texts) == 0:
                texts = doc.find_all(fmt['text3'])
        if len(texts)==0:
            print(f"Warning: no text found in {sgml_file}:{docno}")


        #for text in texts:
            #towrite.append(text.text.strip())
        towrite = [t.text.strip() for t in texts]
        towrite = "\n".join(towrite).strip()

        if len(towrite)==0:
            continue
        else:
            docd[docno] = towrite
            

    if len(docd.keys())>0:
        for docno in docd.keys():
            write_file = os.path.join(write_dir, docno) + ".txt"
            with open(write_file, 'w', encoding='utf-8') as f:
                f.write(docd[docno]+"\n")
            
        print(f"wrote {len(docd.keys())} files to folder {write_dir}")

if __name__=="__main__":

    mode = sys.argv[1]
    fil = sys.argv[2]
    write_dir = sys.argv[3]

    if mode == "doc":
        parse_write_sgml(fil, write_dir)

    elif mode == "query":
        if len(sys.argv)==5:
            year = str(sys.argv[4])

            extract_queries(fil, write_dir, year)
        else:
            # trec format
            extract_queries(fil, write_dir, dformat="trec")




