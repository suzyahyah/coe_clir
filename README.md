
## Topic Models vs MT

### Dependencies

* Python==3.7
* ElasticSearch 7.5.0, Python Elastic Search Client 7.1.0
* trec_eval 
* pytorch >=1.3
* jieba==0.42.1
* nltk==3.4.5
* pandas==1.0.1
* bs4==4.8.2

### Usage

#### Start and Stop Elastic Search

`bash ./bin/server.sh [start | stop]`

#### Preparing bitext

For MATERIAL, Bitext comes with the MATERIAL Directories

For CLEF, TREC, Bitext is obtained from News-Commentary (WMT19)
http://data.statmt.org/news-commentary/v14/

`bash ./bin/prep_bitext.sh`

#### Run Pipeline in Stages

`bash ./bin/run_{material,clef,trec}.sh` 

* Stage 0: Make Directories and Prepare Data

* Stage 1: Merge Queries, RelAssess, Docs

* Stage 2: Calculate statistics

* Stage 3: Preprocessing Query and Document

* Stage 4: Train Polylingual Topic Models on BiText

* Stage 5: Index and Retrieve Topic Models Document Representations

* Stage 6: Index and Retrieve Translated Documents 

* Stage 7: Combine Doc Retrieval and TM models



---

The Flags for each script are:

* `sstage` - start stage, (integer value from 0 to 7)
* `estage` - end stage, (integer vaue from 0 to 7)

* `processd` - a list which contains the document types that should be processed in each stage. Valid values for TREC and CLEF are `doc`, `query`, `rel` ,`bitext,` MATERIAL additionally has `mt1` and `mt2` documents that can be processed.

  * `translate`- 0 or 1, only available in `run_clef.sh` and `run_trec.sh`. Translates documents from src language to English. See `run_{clef,trec}.sh` for more information. This step requires GPU and CUDA10 (for fairseq). 

     

* `reset` - 0 or 1, removes all saved work and copies from the raw data folder. We rarely want to do this.
* `L=([lang]=../file_path)`- contains file paths and languages 

For example if we wanted to calculate statistics of the query documents for Russian in CLEF, we would run the script `./bin/run_clef.sh` with the following flags:

`sstage=2`
`estage=2`
`processd=(query)`
`declare -A L=(['russian']=${DOCS}/Russian_data)`

#### Adding Statistics (Modifying Stage2):

In `utils.sh`: modify `print_rel(), print_query(), doc_stats()`

Note the number of lines in docs for non-MATERIAL datasets do not need to match up because it
is not a line by line translation. 

#### Adding Preprocessing (Modifying Stage3):

Overwrite `src/preprocess.py` which preprocess text for either topic modeling `mode=tm` or bm25 retrieval `mode=bm25`

#### Train Polylingual Topic Models (Modifying Stage 4):

This relies on `./bin/runPolyTM.sh` which is an interface to the mallet library for CLEF, TREC and MATERIAL. Not easy to make modifications on the Polylingual Topic Modeling algorithm unless we modify the java code within the mallet library directly. 

#### Indexing and Retrieval with ElasticSearch (Modifying Stage 5 and 6):

The main entry point to Indexing and Retrieval is `src/main.py`,and takes arguments

*  `mode` "doc" or "tm"
* `dims` for "tm", can be left blank or as 0 for "doc"
* `query_fn` query filename in either topic model or document form
* `tfn` target file directories either topic model of document form
* `resf` name of results file to write ranking and MAP scores to.

Templates for Elasticsearch are in `templates/{index,mapping}_{tm,doc}.json`. We need both a index and a mapping file for either Topic Model representation or regular documents. Evaluation uses `trec_eval` 

#### Sweeping across interpolations

This stage relies on `combine_model_sweep()` from `utils.sh` to do the parameter sweep, and `src/combine_models.py`to do the interpolation. `combine_model_sweep()`selects the topic with the best MAP score, and uses the topic representation retrieval scores to combine with the document representation scores `(1-weight) * topic_vector_ranking + weight*document_ranking`

All intermediate results produced by Stage 5, 6, are saved in `results.`

#### After Stage 7, Generate report (TREC/CLEF)

Finally, we generate a report for the dataset and the language with the following helper script. 

`bash bin/report.sh {TREC,CLEF,MATERIAL} {lang}`

e.g.,

`bash report.sh TREC chinese`

saves the results to `reports/TREC/chinese.txt`

For "Indiv Systems", the "tm" (topic modeling) system has the top k number of topics reported, but MT systems do not.
For "Combined Systems", the interpolation weight is given in ()
