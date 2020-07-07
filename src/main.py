#!/usr/bin/python3
# Author: Suzanna Sia

import pdb
import numpy as np
import os
import sys
import json

from elasticsearch import Elasticsearch
from elasticsearch import helpers

import utils
import argparse

argparser = argparse.ArgumentParser()
argparser.add_argument('--mode', type=str, required=True)
argparser.add_argument('--dims', type=int, default=0)
argparser.add_argument('--baseline', type=int, default=0, required=False)
argparser.add_argument('--query_fn', type=str, required=True)
argparser.add_argument('--target_fn', type=str, required=False)
argparser.add_argument('--resf', type=str, required=False)

args = argparser.parse_args()


INDEX_NAME = "coe"
SEARCH_SIZE = 5

def init():
    client = Elasticsearch([{'host':'localhost', 'port':9200}])
    mode = args.mode
    dims = args.dims

    client = setup_es(client, INDEX_NAME, mode, dims)

    # Topics
    if "tm" in mode:
        target_json = utils.topics_to_json(args.target_fn)
        queries_json = utils.topics_to_json(args.query_fn, query=True)

        if args.baseline == 1:
            print(">Running random baseline")
            for json in target_json:
                randomvals = np.random.random(dims).tolist()
                json['doctopic'] = randomvals

            for json in queries_json:
                randomvals = np.random.random(dims).tolist()
                json['doctopic'] = randomvals
            
    # Text
    elif mode == "doc":
        target_json = utils.docs_to_json(args.target_fn)
        queries_json = utils.queries_to_json(args.query_fn)

    # refac this into utils
    #print(client.indices.get_mapping(index=INDEX_NAME))
    print("indexing docs..")
    errors = helpers.bulk(client, target_json, refresh=True)

    scores = score_queries(client, queries_json, mode)
    with open(args.resf, 'w') as f:
        f.write("\n".join(scores))

    print(f"Results written to: {args.resf}")

def score_queries(client, queries_json, mode):
    script_query = utils.get_query_template(mode=mode)
    scores = []

    print("searching for queries..")
    no_results = []
    seen = set()


    for q in queries_json:
        if q['docid'] in seen:
            print("Duplicate query:")
            continue
        else:
            seen.add(q['docid'])

        if mode == "doc":
            script_query['query']['simple_query_string']['query'] = q['doc_text']

        if mode == "tm":
            script_query['query']['script_score']['script']['params']['query_vector'] = q['doctopic']

        if mode == "combine":
            script_query['query']['function_score']['query']['match']['doc_text'] \
            = q['doc_text']

        response = client.search(INDEX_NAME, script_query)

        if response['hits']['total']['value']==0:
            no_results.append(q['docid'])


        for r in range(len(response['hits']['hits'])):
            name_id = response['hits']['hits'][r]['_source']['docid']
            score = response['hits']['hits'][r]['_score']
            res = f"{q['docid']}\tQO\t{name_id}\t{r}\t{score}\tSTANDARD"
            scores.append(res)

    for i, qid in enumerate(no_results):
        # need to give a different i, otherwise trec_eval will complain
        res = f"{qid}\tQ0\tdoc{i}\t0\t0\tSTANDARD"
        scores.append(res)

    print("No. of queries with no result:", len(no_results))

    return scores

def setup_es(client, INDEX_NAME, mode, dims=0):

    if client.indices.exists(index=INDEX_NAME):
        client.indices.delete(index=INDEX_NAME)

    with open(f'templates/index_{mode}.json', 'r') as f:
        settings = json.load(f)

    with open(f'templates/mapping_{mode}.json', 'r') as f:
        mapping = json.load(f)

    if int(dims)!=0:
        settings['mappings']['properties']['doctopic']['dims'] = dims
        mapping['properties']['doctopic']['dims'] = dims

    client.indices.create(index=INDEX_NAME, body=settings)
    client.indices.put_mapping(index=INDEX_NAME, body=mapping)
    return client

if __name__=="__main__":
    init()


