#!/usr/bin/env python

import nltk
import pdb
from pprint import pprint
import json
from collections import defaultdict
import sys


mql_spec="""MATERIAL_QUERY -> LEXICAL_COMPONENT | CONCEPTUAL_COMPONENT | CONJUNCTION
CONJUNCTION -> LEXICAL_COMPONENT "," LEXICAL_COMPONENT | LEXICAL_COMPONENT "," CONCEPTUAL_COMPONENT | CONCEPTUAL_COMPONENT "," LEXICAL_COMPONENT
CONCEPTUAL_COMPONENT -> SIMPLE_CONCEPTUAL | EXAMPLE_OF | EXAMPLE_OF CONSTRAINT | EXTENDED_EXAMPLE_OF
EXTENDED_EXAMPLE_OF -> '"' WORD_OR_WORDS S EXAMPLE_OF '"' | '"' WORD_OR_WORDS S EXAMPLE_OF CONSTRAINT '"' | '"' EXAMPLE_OF S WORD_OR_WORDS '"' | '"' EXAMPLE_OF CONSTRAINT S WORD_OR_WORDS '"'
EXAMPLE_OF -> EX "(" WORD_OR_WORDS ")"
SIMPLE_CONCEPTUAL -> '"' ONE_CONSTITUENT_TERM '"' '+' CONSTRAINT | '"' MORPHLESS_MAYBE_CONSTRAINED_TERM_CONTENT '"' '+' | '"' WORDS '"' '+' CONSTRAINT | WORD '+' CONSTRAINT | WORD '+'
MORPHLESS_MAYBE_CONSTRAINED_TERM_CONTENT -> CONSTITUENT_AND_CONSTRAINT | ONE_CONSTRAINT_TERM | ONE_CONSTITUENT_TERM | WORDS
LEXICAL_COMPONENT -> '"' MAYBE_CONSTRAINED_TERM_CONTENT '"' | '"' UNCONSTRAINED_TERM_CONTENT '"' CONSTRAINT | WOM | WOM CONSTRAINT
MAYBE_CONSTRAINED_TERM_CONTENT -> MORPH_AND_CONSTITUENT_AND_CONSTRAINT | MORPH_AND_CONSTRAINT | CONSTITUENT_AND_CONSTRAINT | MORPH_AND_CONSTITUENT | ONE_MORPH_TERM | ONE_CONSTITUENT_TERM | ONE_CONSTRAINT_TERM | WORDS
UNCONSTRAINED_TERM_CONTENT -> MORPH_AND_CONSTITUENT | ONE_MORPH_TERM | ONE_CONSTITUENT_TERM | WORDS
WOM -> WORD | MORPH
MORPH_AND_CONSTITUENT_AND_CONSTRAINT -> MORPH_AND_CONSTITUENT ONE_CONSTRAINT_SUFFIX | MORPH_AND_CONSTRAINT S ONE_CONSTITUENT | CONSTITUENT_AND_CONSTRAINT S ONE_MORPH
MORPH_AND_CONSTITUENT -> ONE_MORPH S ONE_CONSTITUENT | ONE_CONSTITUENT S ONE_MORPH
MORPH_AND_CONSTRAINT -> ONE_MORPH ONE_CONSTRAINT_SUFFIX | WORD_OR_WORDS CONSTRAINT S ONE_MORPH
CONSTITUENT_AND_CONSTRAINT -> ONE_CONSTITUENT_PREFIX ONE_CONSTRAINT_SUFFIX | WORD_OR_WORDS CONSTRAINT S ONE_CONSTITUENT
ONE_MORPH -> ONE_MORPH_TERM | MORPH
ONE_MORPH_TERM -> MORPH S WORD_OR_WORDS | WORD_OR_WORDS S MORPH | WORD_OR_WORDS S MORPH S WORD_OR_WORDS
ONE_CONSTRAINT_SUFFIX -> CONSTRAINT S WORD_OR_WORDS | CONSTRAINT
ONE_CONSTRAINT_TERM -> WORDS CONSTRAINT | WORD_OR_WORDS CONSTRAINT S WORD_OR_WORDS
ONE_CONSTITUENT -> ONE_CONSTITUENT_TERM | CONSTITUENT
ONE_CONSTITUENT_TERM -> ONE_CONSTITUENT_PREFIX | WORD_OR_WORDS S CONSTITUENT
ONE_CONSTITUENT_PREFIX -> CONSTITUENT S WORD_OR_WORDS | WORD_OR_WORDS S CONSTITUENT S WORD_OR_WORDS
CONSTRAINT -> "[" CONSTRAINT_TYPE ":" WORD_OR_WORDS "]"
CONSTITUENT -> "(" WORDS ")"
MORPH -> "<" WORD_OR_WORDS ">"
WORD_OR_WORDS -> WORD | WORDS
WORDS -> WORD S WORDS | WORD S WORD
WORD -> W
W -> C W | C
EX -> "E" "X" "A" "M" "P" "L" "E" "_" "O" "F"
CONSTRAINT_TYPE -> "e" "v" "f" | "s" "y" "n" | "h" "y" "p"
C -> "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" | "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "-" | "'" | "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
S -> " " S | " "
"""



class QueryParser(object):
    """Query processor that interprets MATERIAL queries"""

    def __init__(self):
        mql_grammar = nltk.CFG.fromstring(mql_spec)
        self._parser = nltk.ChartParser(mql_grammar)

    def parse_to_json(self, material_query):
        tree = self.parse_one(material_query)
        if tree:
            return self.tree2json(tree)
        else:
            return None

    def parse_one(self, material_query):
        return self._parser.parse_one(material_query, tree_class=nltk.tree.ParentedTree)

    def createdict(self, tree):
        d = defaultdict(str)
        L = tree.label()
        if L == 'LEXICAL_COMPONENT':
            d['query_type'] = 'lexical'
        elif L == 'CONCEPTUAL_COMPONENT':
            d['query_type'] = 'conceptual'
        return d


    def tree2json(self, tree):
        s = ''
        for i, subtree in enumerate(tree):
            if isinstance(subtree, nltk.tree.ParentedTree):
                L = subtree.label()
                s += '[ '
                if L == 'CONJUNCTION':
                    d1 = self.createdict(subtree[0])
                    s += json.dumps(self.tree2dict(subtree[0], d1))
                    s += ', '
                    d2 = self.createdict(subtree[2])
                    s += json.dumps(self.tree2dict(subtree[2], d2))
                else:
                    d = self.createdict(subtree)
                    s += json.dumps(self.tree2dict(subtree, d))
                s += ']'
        #import pdb
        #pdb.set_trace()
        return s


    def tree2dict(self, tree, d):
        for i, subtree in enumerate(tree):
            if isinstance(subtree, nltk.tree.ParentedTree):
                L = subtree.label()
                #print(i,L,subtree)
                #print("  -")
                if L == 'WORD':
                    d['query_string'] += "%s " %(''.join(subtree.leaves()))
                    self.tree2dict(subtree,d)
                elif L == 'CONSTRAINT':
                    d['semantic_constraint_class'] = ''.join(subtree[1].leaves())
                    d['semantic_constraint_string'] = ''.join(subtree[3].leaves())
                elif L == 'MORPH':
                    d['morphology_constraint'] = ''.join(subtree[1].leaves())
                    self.tree2dict(subtree,d)
                elif L == 'EXAMPLE_OF':
                    d['example_of'] = ''.join(subtree[2].leaves())
                    self.tree2dict(subtree,d)
                else:
                    # recursion
                    self.tree2dict(subtree,d)
        return d



def test(long_example=False):
    if long_example:
        example_mqs = []
        with open("queries/query_list.tsv",'r') as f:
            f.readline()
            for l in f:
                _, q,_ = l.split("\t")
                example_mqs.append(q)
    else:
        example_mqs = ['''EXAMPLE_OF(virus)[evf:medicine]''',
                       '''"(word word) <word> word[evf:test]"''',
                       '''"<contaminated> water"''',
                       '''"<packets> of tea"''',
                       '''"<woke up> early"''',
                       '''"<word> word[evf:word]"''',
                       '''"musician <would play>"''',
                       '''"sheep <will jump>"''',
                       '''<morph>''',
                       '''<word word>''',
                       '''"red EXAMPLE_OF(attire)"''',
                       '''"small green EXAMPLE_OF(vegetable)"''',
                       '''"EXAMPLE_OF(attire)[evf:clothing] red"''',
                       '''insect,"my dog"''',
                       '''"blood pressure"[hyp:medical condition]''',
                       '''"<broadcasted> live[syn:in real time]"''',
                       '''boxing+[evf:sports],shoes[hyp:footwear]''',
                       '''simple''',
        ]

        
    qp = QueryParser()
    for i,mq in enumerate(example_mqs):
        x = qp.parse_to_json(mq)
        print(i)
        print(mq)
        print(x)
        print("------------")

# Modified from original file
if __name__ == "__main__":
    fn = sys.argv[1]
    qp = QueryParser()

    with open(fn, 'r') as f:
        queries = f.readlines()

    queries = [q.split('\t') for q in queries if "query_id" not in q]
    new_queries = []

    for i, q in enumerate(queries):

        j = qp.parse_to_json(q[1])
        if j is None:
            #Refac this
            pdb.set_trace()

        jstring = json.loads(j)
        snippets = []
        for snippet in jstring:
            snippets.append(snippet['query_string'])
        snippets = " ".join(snippets)

        new_queries.append(q[0] + "\t" + snippets.strip())

    new_queries = "\n".join(new_queries)
    with open(fn+".qp", 'w') as f:
        f.write(new_queries+"\n")

    print("queries written to:", fn+".qp")
