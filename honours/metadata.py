from os import listdir
from os.path import isfile, join
from os import environ
import os
import pandas as pd
import re
from collections import Counter
import html
from enum import Enum
import _pickle as pkl
import unidecode
from _data_cleaning.nametools import process_str


#constructs dataframe with authors papers and names

class Gender(Enum):
    male = 0
    female = 1
    unknown = 2
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
class ACL_metadata():


	def __init__(self):

		train_dirpath = os.path.join(os.environ["AAN_DIR"],"papers_text")
		self.train_files = [join(environ["AAN_DIR"],"papers_text/{0}".format(fn)) 
		for fn in listdir(join(environ["AAN_DIR"],"papers_text/")) if isfile(join(train_dirpath, fn)) and "txt" in fn]

		tf  = set()
		for f in self.train_files:
			i = self.get_id(f)
			tf.add(i)

		self.metadata_path = os.path.join(os.environ["AAN_DIR"],"release/2014/acl-metadata.txt")


		with open("known_names.pkl","rb") as file:
			dicty = pkl.load(file)

		with open("bingclassif.pkl","rb") as file:
			dicty2 = pkl.load(file)

		# known authors
		self.known = set()
		self.known_f = set()
		self.known_m = set()
		self.unk = set()
		# all authors in our papers
		self.auths = set()
		self.ids = set()

		dic = []

		fields = ["id", "authors", "title", "venue", "year","genders"]

		with open(self.metadata_path,"r", encoding="utf-8") as f:
			paper_data = f.read().split("\n\n")
		for idx,paper in enumerate(paper_data):
			values = paper.split("\n")[:len(fields)-1]

			values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
			if(values["id"]) in self.ids:
				continue
			self.ids.add(values["id"])

			values["authors"] = values["authors"].split("; ")
			values["genders"] = []
			values["year"] = int(values["year"])
			for i,auth in enumerate(values["authors"]):
				auth = auth.strip()
				self.auths.add(auth)
				gender = dicty.get(auth, Gender.unknown)
				if gender == Gender.unknown:
					gender = dicty2.get(auth, Gender.unknown)
				auth = process_str(auth)
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

		self.meta_files = [join(environ["AAN_DIR"],"papers_text/{0}.txt".format(fn)) 
		for fn in list(self.meta_df.index)]

	def get_id(self,f):
		return f.split("/")[-1][:-4]