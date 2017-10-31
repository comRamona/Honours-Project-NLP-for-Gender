from os import listdir
from os.path import isfile, join
from os import environ
import os
import pandas as pd
import re
from collections import Counter
import html


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
class ACL_metadata(Object):

	def __init__(self):

        self.train_files = [join(environ["AAN_DIR"],"papers_text/{0}".format(fn)) for fn in 
               listdir(join(environ["AAN_DIR"],"papers_text/")) if isfile(join(train_dirpath, fn)) and "txt" in fn]

         self.metadata_path = os.path.join(os.environ["AAN_DIR"],"release/2014/acl-metadata.txt")

 
	    self.papers_idx = []
		fields = ["id", "authors", "title", "venue", "year","genders"]
		with open(self.metadata_path,"r", encoding="utf-8") as f:
		    paper_data = f.read().split("\n\n")
		    for idx,paper in enumerate(paper_data):
		        values = paper.split("\n")[:len(fields)-1]

		        values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))

		        self.papers_idx.append(values["id"])



		female_paths = [os.path.join(os.environ["AAN_DIR"],"save",f) for f in ["acl-female.txt", "machine_females.txt", "machine_femalesNAM.txt"]]

		male_paths = [os.path.join(os.environ["AAN_DIR"], "save", f) for f in ["acl-male.txt", "machine_males.txt", "machine_malesNAM.txt"]]

		self.females = set()
		self.males = set()
		for file in female_paths:
		    with open(file, 'r', encoding = "utf-8") as f:
		        self.females.update(map(lambda x:  html.unescape(x.strip()), f.read().split("\n")))

		for file in male_paths:
		    with open(file, 'r', encoding = "utf-8") as f:
		        self.males.update(map(lambda x:  html.unescape(x.strip()), f.read().split("\n")))




        # known authors
	    self.known = set()
	    # all authors in our papers
	    self.auths = set()

	    with open(ids_path,"r", encoding="utf-8") as f:
	        paper_data = f.read().split("\n\n")
	        for idx,paper in enumerate(paper_data):
	            values = paper.split("\n")[:len(fields)-1]

	            values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
	            
	            values["authors"] = values["authors"].split("; ")
	            values["genders"] = []
	            for i,auth in enumerate(values["authors"]):  
	                auth = auth.strip() 
	                auth = html.unescape(auth)
	                self.auths.add(auth)
	                gender = Gender.unknown
	                if auth in females:
	                    gender = Gender.female
	                    self.known.add(auth)
	                elif auth in males:
	                    gender = Gender.male
	                    self.known.add(auth)
	                values["genders"].append(gender)
	           
	    # pandas dataframe to hold our papers and gender
	    self.df = pd.DataFrame(dic).set_index(["id"])