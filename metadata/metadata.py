from os import listdir
from os.path import isfile, join
from os import environ
import logging
import os
import pandas as pd
import re
from metadata import Gender
import _pickle as pkl
from _name_classification.nametools import process_str as process_str


logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = [logging.StreamHandler()]
# constructs dataframe with authors papers and names

class ACL_metadata():

    def __init__(self):

        logger.warning("Remember to use acl.modeling_files and modeling_df for topic modeling")

        with open("bad_pdfs.pkl", "rb") as f:
            bad_ids = pkl.load(f)
            bad_ids = set(map(lambda x: x[0], bad_ids))

        train_dirpath = os.path.join(os.environ["AAN_DIR"], "papers_text")
        self.train_files = sorted([join(environ["AAN_DIR"], "papers_text",
                                 fn) for fn in listdir(join(environ["AAN_DIR"],
                                                            "papers_text")) if isfile(join(train_dirpath,
                                                                                           fn)) and "txt" in fn and fn[:-4] not in bad_ids],
                                                                                            key = lambda x: self.get_id(x))

        tf = set()
        for f in self.train_files:
            i = self.get_id(f)
            tf.add(i)

        self.metadata_path = os.path.join(os.environ["AAN_DIR"], "release", "2014", "acl-metadata.txt")

        with open(os.path.join(os.environ['AAN_DIR'], "save", "known_names.pkl"), "rb") as file:
            dicty = pkl.load(file)

        # known authors
        self.known = set()
        self.known_f = set()
        self.known_m = set()
        self.unk = set()
        # all authors in our papers
        self.auths = set()
        self.ids = set()

        dic = []

        fields = ["id", "authors", "title", "venue", "year", "genders"]

        with open(self.metadata_path, "r", encoding="utf-8") as f:
            paper_data = f.read().split("\n\n")
        for idx, paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields) - 1]

            values = dict(zip(fields, [re.search(r'{(.*?)}', s).group(1) for s in values] + [[]]))
            if(values["id"]) in self.ids:
                continue
            self.ids.add(values["id"])

            values["authors"] = values["authors"].split("; ")
            values["genders"] = []
            values["year"] = int(values["year"])
            for i, auth in enumerate(values["authors"]):
                auth = auth.strip()
                gender = dicty.get(auth, Gender.unknown)
                auth = process_str(auth)
                self.auths.add(auth)
                if gender == Gender.female:
                    self.known.add(auth)
                    self.known_f.add(auth)
                elif gender == Gender.male:
                    gender = Gender.male
                    self.known.add(auth)
                    self.known_m.add(auth)
                else:
                    self.unk.add(auth)
                values["authors"][i] = auth
                values["genders"].append(gender)
            dic.append(values)

        # pandas dataframe to hold our papers and gender
        self.meta_df = pd.DataFrame(dic).set_index(["id"])

        self.meta_files = sorted([join(environ["AAN_DIR"], "papers_text/{0}.txt".format(fn))
                           for fn in list(self.meta_df.index)], key = lambda x: self.get_id(x))


        ids = set(self.meta_df.index)
        tf = set()
        for f in self.train_files:
            i = self.get_id(f)
            tf.add(i)

        interesting = tf.intersection(ids)

        self.modeling_df = self.meta_df.loc[interesting]
        self.modeling_files = sorted([join(environ["AAN_DIR"], "papers_text/{0}.txt".format(fn))
                               for fn in list(self.modeling_df.index)], key = lambda x: self.get_id(x))

    def get_id(self, f):
        return f.split("/")[-1][:-4]