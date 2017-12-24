import os
from enum import Enum
import pandas as pd
import re
from collections import Counter
import html
import re
from _name_classification.nametools import process_str
from metadata import Gender
import _pickle as pkl
from _name_classification.classifyname import NC


#this file does all the classification. uses both name classification and face detection

def classify():
    nc = NC()

    ids_path = os.path.join(os.environ["AAN_DIR"],
        "release/2014/acl-metadata.txt")

    female_paths = [os.path.join(os.environ["AAN_DIR"], "save/",
        f) for f in ["acl-female.txt", "machine_females.txt", "machine_femalesNAM.txt", "femalesfn1.txt"]]

    male_paths = [os.path.join(os.environ["AAN_DIR"], "save/",
        f) for f in ["acl-male.txt", "machine_males.txt", "machine_malesNAM.txt","malesfn1.txt"]]

    females = set()
    males = set()
    for file in female_paths:
        with open(file, 'r', encoding = "utf-8") as f:
            females.update(map(lambda x:  x.strip(), f.read().split("\n")))

    for file in male_paths:
        with open(file, 'r', encoding = "utf-8") as f:
            males.update(map(lambda x: x.strip(), f.read().split("\n")))

    unsure = set()
    with open(os.path.join(os.environ["AAN_DIR"],"save/","acl-unknown.txt"),"r", encoding="utf-8") as f:
        unsure.update(map(lambda x:  x.strip(), f.read().split("\n")))

    print(unsure)
    new_unkown = set()
    dic = []
    fields = ["id", "authors", "title", "venue", "year","genders"]
    prev=[]
    processed = set()
    auths = set()
   
    with open(ids_path,"r", encoding="utf-8") as f:
        paper_data = f.read().split("\n\n")
        for idx,paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields)-1]

            values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
            if int(values["year"])<=2008:
                continue
            
            values["authors"] = values["authors"].split("; ")
            for i,auth in enumerate(values["authors"]):  
                auth = auth.strip()
                auths.add(auth)
                gender = Gender.unknown
                if auth in processed:
                    continue
                processed.add(auth)
                if auth in females:
                    gender = Gender.female
                    dic[auth] = Gender.female
                elif auth in males:
                    gender = Gender.male
                    dic[auth] = Gender.male
                # elif auth not in known_unknowns:
                else:
                    # no face detection
                    gender = nc.classify_name(auth, False)
                    if gender[0] != Gender.unknown:
                        dic[auth] = gender[0]
               

    with open(os.path.join(os.environ['AAN_DIR'],"save","classifier_results.pkl"),"wb") as file:
        pkl.dump(dic,file)

