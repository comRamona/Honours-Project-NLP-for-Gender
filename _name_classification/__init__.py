#combine files classified with classifier and those from Jurafsky and from crowdsourcing

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
from _name_classification import main_classify_all
import logging



logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


if not os.path.isfile(os.path.join(os.environ['AAN_DIR'],"save","classifier_results.pkl")):
    logger.info("Classifier has not been run. This may take some time.")
    import main_classify_all as mca 
    mca.classify()

if not os.path.isfile(os.path.join(os.environ['AAN_DIR'],"save","known_names.pkl")):

    with open(os.path.join(os.environ['AAN_DIR'],"save","classifier_results.pkl"),"rb") as file:
        dic = pkl.load(file)

    nc = NC()

    ids_path = os.path.join(os.environ["AAN_DIR"],
        "release/2014/acl-metadata.txt")

    female_paths = [os.path.join(os.environ["AAN_DIR"], "save/",
        f) for f in ["acl-female.txt", "femalesfn1.txt", "md-girls.txt"]]

    male_paths = [os.path.join(os.environ["AAN_DIR"], "save/",
        f) for f in ["acl-male.txt", "malesfn1.txt","md-guys.txt"]]

    females = set()
    males = set()
    for file in female_paths:
        with open(file, 'r', encoding = "utf-8") as f:
            females.update(map(lambda x:  x, f.read().split("\n")))

    for file in male_paths:
        with open(file, 'r', encoding = "utf-8") as f:
            males.update(map(lambda x: x, f.read().split("\n")))

    c=0
    new_unkown = set()
    processed = set()
    fields = ["id", "authors", "title", "venue", "year","genders"]

    with open(ids_path,"r", encoding="utf-8") as f:
        paper_data = f.read().split("\n\n")
        for idx,paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields)-1]

            values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
          
            values["authors"] = values["authors"].split("; ")
            for i,auth in enumerate(values["authors"]):  
                auth = auth.strip()
                if auth in processed:
                    continue
                processed.add(auth)
                gender = Gender.unknown
                if auth in females:
                    gender = Gender.female
                    dic[auth] = gender
                elif auth in males:
                    gender = Gender.male
                    dic[auth] = gender
                # elif auth not in known_unknowns:
                elif auth not in dic:
                    c += 1
                    continue
     
          
    #df = pd.DataFrame(dic)#.set_index(["id"])
    with open(os.path.join(os.environ["AAN_DIR"],"idk2008.txt"),"w", encoding="utf-8") as f:
        f.write("\n".join(new_unkown))

    logger.info("CLassified:",len(dic))
    logger.info("Unknown:", len(c))
    with open(os.path.join(os.environ['AAN_DIR'],"save","known_names.pkl"),"wb") as file:
        pkl.dump(dic,file)
    logger.info("Known names saved successfully in aan/save/known_names.pkl")




