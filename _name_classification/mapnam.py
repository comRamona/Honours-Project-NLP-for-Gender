
import re
from collections import Counter, defaultdict
import os
from pprint import pprint
from html.parser import HTMLParser

# parse NAM Classifier results form file

machine_females = open(os.path.join(os.environ["AAN_DIR"],"save/machine_femalesNAM.txt"),"w", encoding="utf-8")
machine_males = open(os.path.join(os.environ["AAN_DIR"],"save/machine_malesNAM.txt"),"w", encoding="utf-8")
machine_unsure = open(os.path.join(os.environ["AAN_DIR"],"save/machine_nochanceNAM.txt"),"w", encoding="utf-8")
pars = HTMLParser()
with open(os.path.join(os.environ["AAN_DIR"],"namresults.txt"),"r", encoding="utf-8") as f:
    unknown_names = f.read().split("\n")
    males=0
    females=0
    new_unk = set()
    p = re.compile("\(u.(.+)., '(.*)', (.*)\)")

    for line in unknown_names:

        if not line: continue
        
        m = p.match(line)
       

        name = pars.unescape(m.group(1))
        gender = m.group(2).strip()
        scale = float(m.group(3))
        if gender == "unknown": 
            machine_unsure.write(name+ " " + str(scale) + "\n")
            continue
        if(abs(scale) < 0.2): 
            machine_unsure.write(name+ "\n")
            continue
        if gender == "female":
            machine_females.write(name + "\n")
            females += 1
        elif gender == "male":
            machine_males.write(name + "\n")
            males += 1

    print(males, females)
       

