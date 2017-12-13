import os
from enum import Enum
import pandas as pd
import re
from collections import Counter
import html
import re
from nametools import process_str
from metadata import Gender
import _pickle as pkl
from classifyname import NC

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


dic = {}
c=0
new_unkown = set()
processed = set()
fields = ["id", "authors", "title", "venue", "year","genders"]


with open("knownplus.pkl","rb") as file:
    dic = pkl.load(file)

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
            if auth in dic:
                continue
            gender = Gender.unknown
            if auth in females:
                gender = Gender.female
                dic[auth] = gender
            elif auth in males:
                gender = Gender.male
                dic[auth] = gender
            # elif auth not in known_unknowns:
            else:
                if int(values["year"]) > 2008:
                    gender = nc.classify_name(auth, False)
                    if gender[0] != Gender.unknown:
                        dic[auth] = gender[0]
                        print(auth,gender)
                    else:
                        new_unkown.add(auth)
                        c += 1
 
      
#df = pd.DataFrame(dic)#.set_index(["id"])
with open(os.path.join(os.environ["AAN_DIR"],"idk2008.txt"),"w", encoding="utf-8") as f:
    f.write("\n".join(new_unkown))

print(len(dic))
print(c)
with open("knownpluss.pkl","wb") as file:
    pkl.dump(dic,file)


