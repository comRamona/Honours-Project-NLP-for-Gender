# -*- coding: utf-8 -*-
import os
from io import open
import re
from collections import Counter, defaultdict
from nametools import process_str_for_similarity_cmp
#1
#requires python2
def gender_machine():
    import sexmachine.detector as gender
    d = gender.Detector()

    machine_females = open(os.path.join(os.environ["AAN_DIR"],"machine_females_norm.txt"),"w", encoding="utf-8")
    machine_males = open(os.path.join(os.environ["AAN_DIR"],"machine_males_norm.txt"),"w", encoding="utf-8")

    machine_unknown = open(os.path.join(os.environ["AAN_DIR"],"machine_unknown_norm.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"recent_names"),"r", encoding="utf-8") as f:
        unknown_names = set(map(lambda x: x.strip(), f.read().split("\n")))
        males=0
        females=0
        unk=0
        new_unk = set()
        regex = re.compile(r"\w+\.", re.IGNORECASE)

        for name in unknown_names:
            name = name.strip()
            try:
                fn = name.split(",")[1].strip()
                no_initials = process_str_for_similarity_cmp(regex.sub("",fn).strip())
                gn = d.get_gender(no_initials)
                if gn == "male":
                    males += 1
                    machine_males.write(name + "\n")
                elif gn == "female":
                    females +=1
                    machine_females.write(name + "\n")
                else:
                    new_unk.add(name)
            except:
                print("ERR1: ",name)
                new_unk.add(name)

        machine_unknown.write("\n".join(new_unk))

        print(males, females, len(new_unk), len(unknown_names))

        machine_females.close()
        machine_males.close()


gender_machine()