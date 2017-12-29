from os import listdir
from os.path import isfile, join
from os import environ
import os
import pandas as pd
import re
from metadata import Gender
import _pickle as pkl
import unidecode
from _name_classification.nametools import process_str as process_str





""""
train_files 
metadata_path
papers_idx
females
males
known
auths
df
"""


class ACL_fulltext():

    def __init__(self):

        train_dirpath = os.path.join(os.environ["AAN_DIR"], "papers_text")
        self.train_files = [join(environ["AAN_DIR"], "papers_text/{0}".format(fn))
                            for fn in listdir(join(environ["AAN_DIR"], "papers_text/")) if isfile(join(train_dirpath, fn)) and "txt" in fn]

        tf = set()
        for f in self.train_files:
            i = self.get_id(f)
            tf.add(i)

        self.metadata_path = os.path.join(os.environ["AAN_DIR"], "release/2014/acl-metadata.txt")

        female_paths = [os.path.join(os.environ["AAN_DIR"], "save", f)
                        for f in ["acl-female.txt", "machine_females.txt", "machine_femalesNAM.txt"]]

        male_paths = [os.path.join(os.environ["AAN_DIR"], "save", f)
                      for f in ["acl-male.txt", "machine_males.txt", "machine_malesNAM.txt"]]

        self.females = set()
        self.males = set()
        for file in female_paths:
            with open(file, 'r', encoding="utf-8") as f:
                self.females.update(map(lambda x: process_str(x), f.read().split("\n")))

        for file in male_paths:
            with open(file, 'r', encoding="utf-8") as f:
                self.males.update(map(lambda x: process_str(x), f.read().split("\n")))

        # known authors
        self.known = set()
        # all authors in our papers
        self.auths = set()
        ids = set()

        dic = []

        fields = ["id", "authors", "title", "venue", "year", "genders"]

        with open(self.metadata_path, "r", encoding="utf-8") as f:
            paper_data = f.read().split("\n\n")
        for idx, paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields) - 1]

            values = dict(zip(fields, [re.search(r'{(.*?)}', s).group(1) for s in values] + [[]]))
            if(values["id"]) in ids:
                continue
            if(values["id"]) not in tf:
                continue
            ids.add(values["id"])

            values["not_normalised"] = values["authors"].split("; ")
            values["authors"] = []
            values["genders"] = []
            for i, auth in enumerate(values["not_normalised"]):
                auth = process_str(auth)
                values["authors"].add(auth)
                self.auths.add(auth)
                gender = Gender.unknown
                if auth in self.females:
                    gender = Gender.female
                    self.known.add(auth)
                elif auth in self.males:
                    gender = Gender.male
                    self.known.add(auth)
                values["genders"].append(gender)
            dic.append(values)

        # pandas dataframe to hold our papers and gender
        self.df = pd.DataFrame(dic).set_index(["id"])

        with open("bad_pdfs.pkl", "rb") as f:
            ids = pkl.load(f)
            ids = list(map(lambda x: x[0], ids))

        self.meta_df = self.df

        self.df = self.df.drop(ids)
        self.train_files = [join(environ["AAN_DIR"], "papers_text/{0}.txt".format(fn))
                            for fn in list(self.df.index)]

    def get_id(self, f):
        return f.split("/")[-1][:-4]
