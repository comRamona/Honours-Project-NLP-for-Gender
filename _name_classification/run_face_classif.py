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

    with open(os.path.join(os.environ["AAN_DIR"],"idk2008.txt"),"r", encoding="utf-8") as f:
       uk= f.read().split("\n")

    processed = set()
    dic = dict()
    c=0
    i=0
    for auth in uk:
        print(i)
        i+=1
        auth = auth.strip()
        if auth in processed:
            continue
        processed.add(auth)
        if auth in dic:
            continue
        gender = Gender.unknown
       
        gender = nc.classify_name(auth, True)
        if gender[0] != Gender.unknown:
            dic[auth] = gender[0]
            print(auth,gender)
        else:
            c += 1
     
          

    print(len(dic))
    print(c)
    with open(os.path.join(os.environ['AAN_DIR'],"save","bingclassif.pkl"),"wb") as file:
        pkl.dump(dic,file)

