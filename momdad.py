import os
from enum import Enum
import pandas as pd
import re
from collections import Counter
import html
import re
from nametools import process_str
from metadata import Gender



def map_titles():

    momdad = {}

    with open ("/home/rama/Desktop/names-names.csv") as f:
        names = f.read.split("\n")
        for n in names:
            l, f, g = n.split(",")
            if g.strip()=="m":
                


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
            females.update(map(lambda x:  process_str(x), f.read().split("\n")))

    for file in male_paths:
        with open(file, 'r', encoding = "utf-8") as f:
            males.update(map(lambda x: process_str(x), f.read().split("\n")))

    unsure = set()
    with open(os.path.join(os.environ["AAN_DIR"],"save/","acl-unknown.txt"),"r", encoding="utf-8") as f:
        unsure.update(map(lambda x:  process_str(x), f.read().split("\n")))

    print(unsure)
    new_unkown = set()
    dic = []
    fields = ["id", "authors", "title", "venue", "year","genders"]
    prev=[]
    known = set()
    auths = set()
    print(len(females))
    print(len(males))
    print("Mediani, Mohammed" in males)
    with open(ids_path,"r", encoding="utf-8") as f:
        paper_data = f.read().split("\n\n")
        for idx,paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields)-1]

            values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
            if int(values["year"])<=2008:
                continue
            
            values["authors"] = values["authors"].split("; ")
            for i,auth in enumerate(values["authors"]):  
                auth = process_str(auth)
                auths.add(auth)
                gender = Gender.unknown
                if auth in females:
                    gender = Gender.female
                    known.add(auth)
                elif auth in males:
                    gender = Gender.male
                    known.add(auth)
                # elif auth not in known_unknowns:
                else:
                    if auth in unsure:
                        continue
                    new_unkown.add(auth)
                values["genders"].append(gender)
            #dic.append(values)
            prev = values
            #if idx==5:
            #    break
        print(idx)
        print(len(auths))
        print(len(known))
        print(len(new_unkown))
          
    #df = pd.DataFrame(dic)#.set_index(["id"])
    with open(os.path.join(os.environ["AAN_DIR"],"aclr_unknown_after_2009_norm.txt"),"w", encoding="utf-8") as f:
        f.write("\n".join(new_unkown))



def main():
    #nc = NameClassifier()
    #print(nc.classify_unknown_from_known_stats())
    map_titles()

 
 
if __name__ == '__main__':
    main()
