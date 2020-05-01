## Topic Models vs MT

### Dependencies
* Python 3.6
* ElasticSearch 7.5.0, Python Elastic Search CLient
* trec_eval

### Usage
#### Start and Stop Elastic Search
`bash ./bin/server.sh [start | stop]`

#### Corpus Statistics
see stats.txt, generated from stage 0:1

#### Run Pipeline in Stages

`bash ./bin/run_all.sh` 

Process Documents for: Bitext, ANALYSIS, MT1, MT2, Query

* Stage 0: Make Directories and Prepare Data

* Stage 1: Calculate Statistics

* Stage 2: Preprocessing for Documents

* Stage 3: Train Polylingual Topic Model on BiText (up to k topics)

* Stage 4: Index Src Topic Vectors, search with Query Topic Vectors (up to k topics) -> trec_eval

* Stage 5: Index {human, mt1, mt2} documents, search with bm25 query -> trec_eval

#### Running Query-Topic Diagnostics:
`bash ./bin/run_diagnostics.sh`
