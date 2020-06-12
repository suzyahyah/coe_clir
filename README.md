## Topic Models vs MT

### Dependencies
* Python 3.6
* ElasticSearch 7.5.0, Python Elastic Search CLient 7.1.0
* trec_eval

### Usage
#### Start and Stop Elastic Search
`bash ./bin/server.sh [start | stop]`

#### Corpus Statistics
see stats.txt, generated from stage 0:1
Note the number of lines in docs for non-MATERIAL datasets do not need to match up because it
is not a line by line translation. 

#### Preparing bitext
For MATERIAL, Bitext comes with the MATERIAL Directories

For CLEF, TREC, Bitext is obtained from News-Commentary (WMT19)
http://data.statmt.org/news-commentary/v14/

`bash ./bin/prep_bitext.sh`

# Todo: Instructions on how to get parallel corpora

#### Run Pipeline in Stages

`bash ./bin/prep_{material,clef,trec}.sh` 

* Stage 0: Make Directories and Prepare Data

* Stage 1: Merge Queries, RelAssess, Docs

* Stage 2: Calculate statistics

* Stage 3: Preprocessing Query and Document

* Stage 4: Train Polylingual Topic Models on BiText

* Stage 5: Test Topic Models

* Stage 6: Index and Retrieve Docs

* Stage 7: Combine Doc Retrieval and TM models

#### Running Query-Topic Diagnostics:
`bash ./bin/run_diagnostics.sh`

#### After Stage 7, Generate report (TREC/CLEF)

`bash report.sh {dataset} {lang}`

e.g.,

`bash report.sh TREC chinese`
