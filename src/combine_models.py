#!/usr/bin/python3
# Author: Suzanna Sia

import pandas as pd
import sys

def init():
    names = 'qid q0 docid rank score std'.split()
    weight = float(sys.argv[1])
    ranking1 = sys.argv[2]
    ranking2 = sys.argv[3]
    outf = sys.argv[4]

    dfs = []
    dfs.append(pd.read_csv(ranking1, sep="\t", names=names))
    dfs.append(pd.read_csv(ranking2, sep="\t", names=names))
    
    merge1 = dfs[0].merge(dfs[1], on=['qid', 'docid'], how="outer", suffixes=['_1', '_2'])

    for col in merge1.columns:
        merge1[col].fillna(0, inplace=True)


    merge1['score'] = (1-weight)*merge1[f'score_1']+ weight*merge1[f'score_2']
    merge1['ranking'] = [1]*len(merge1)

    outnames = f'qid q0_1 docid ranking score std_1'.split()
    merge1[outnames].to_csv(outf, sep="\t", index=False)

if __name__ == "__main__":
    init()


