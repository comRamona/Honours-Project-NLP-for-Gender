import os
from enum import Enum
import pandas as pd
import re
from collections import Counter
from html.parser import HTMLParser

class Gender(Enum):
    male = 0
    female = 1
    unknown = 2

class NameClassifier():

    def __init__(self):
        female_path = os.path.join(os.environ["AAN_DIR"],
        "acl-female.txt")
        male_path = os.path.join(os.environ["AAN_DIR"],
        "acl-male.txt")

        self.mylog = open(os.path.join(os.environ["AAN_DIR"],
        "mylog.txt"),"a",encoding="utf-8") 

        with open(male_path,"r", encoding="utf-8") as f:
            f = f.read()
            self.male_full_firsts = Counter(filter(lambda n: len(n)>3,self.get_first_names_list(f)))
            self.male_single_firsts = Counter(filter(lambda n: len(n)>3,self.get_first_names_list(f,True)))
        with open(female_path,"r", encoding="utf-8") as f:
            f = f.read()
            self.female_full_firsts = Counter(filter(lambda n: len(n)>3,self.get_first_names_list(f)))
            self.female_single_firsts = Counter(filter(lambda n: len(n)>3,self.get_first_names_list(f,True)))

 
    def get_first_names_list(self,file, further_split = False):
        return list(map(lambda fn: fn[1].strip().split()[0] if further_split==True else fn[1].strip()  ,
            filter(lambda name: len(name)>1, 
                map(lambda name: name.split(",") ,file.split("\n")))))


    def classify_name(self, name, further_split = False):

        name = name.strip().split(",")
        if len(name)<3:
            return Gender.unknown
        if(len(name[1])<=3):
            return Gender.unknown
       
        
        name = name[1].strip().split()[0] if further_split else name[1].strip()
       
        cm = self.male_single_firsts[name] if further_split else self.male_full_firsts[name]
        cf = self.female_single_firsts[name] if further_split else self.female_full_firsts[name]
        if(cm > cf and cf == 0 and cm > 2):
            return Gender.male
        if(cf > cm and cm == 0 and cf > 2):
            return Gender.female
        return Gender.unknown

    def classify_unknown_from_known_stats(self):
        unknown_path = os.path.join(os.environ["AAN_DIR"],
        "machine_set2.txt")
        with open(unknown_path,"r",encoding="utf-8") as f:
            names = set(f.read().split("\n"))

        dic = []
        for name in names:
            c1 = self.classify_name(name,False)
            c2 = self.classify_name(name,True)
            gender = Gender.unknown
            if c1!=c2:
                if c1==Gender.unknown and c2!=Gender.unknown:
                    gender = c2
                elif c2==Gender.unknown and c1!=Gender.unknown:  
                    gender = c1
                elif c1!=Gender.unknown and c2!=Gender.unknown:
                    c1 = Gender.unknown
                    print("Conflict {0}".format(name))
            else:
                gender = c1
            dic.append({"name":name,"gender":gender})

        df = pd.DataFrame(dic)
        cls_m = df[df["gender"]==Gender.male]
        cls_f = df[df["gender"]==Gender.female]
        with open(os.path.join(os.environ["AAN_DIR"],"malesfn1.txt"),"w", encoding="utf-8") as f:
            f.write("\n".join(cls_m["name"]))
        with open(os.path.join(os.environ["AAN_DIR"],"femalesfn1.txt"),"w", encoding="utf-8") as f:
            f.write("\n".join(cls_f["name"]))
        self.mylog.write("\n\nClassify by first name, taking into account just first 2 authors:\n")
        self.mylog.write("Total unknown: {0}. Managed to classify {1} males and " 
           "{2} females ".format(len(df),len(cls_m),len(cls_f)))
       



def map_titles():

    ids_path = os.path.join(os.environ["AAN_DIR"],
        "release/2014/acl-metadata.txt")
    female_path = os.path.join(os.environ["AAN_DIR"],
        "acl-female.txt")
    male_path = os.path.join(os.environ["AAN_DIR"],
        "acl-male.txt")
    female_path2 = os.path.join(os.environ["AAN_DIR"],
        "machine_females.txt")
    male_path2 = os.path.join(os.environ["AAN_DIR"],
        "machine_males.txt")

    with open(female_path,"r",encoding="utf-8") as f, open(female_path2,"r",encoding="utf-8") as f2:
        females = set(list(map(lambda x: x.strip(), f.read().split("\n"))) + list(map(lambda x: x.strip(), f2.read().split("\n"))))

    with open(male_path,"r",encoding="utf-8") as g, open(male_path2,"r",encoding="utf-8") as g2:
        males = set(list(map(lambda x: x.strip(), g.read().split("\n")))  + list(map(lambda x: x.strip(), g2.read().split("\n"))))

    new_unkown = set()
    dic = []
    fields = ["id", "authors", "title", "venue", "year","genders"]
    prev=[]
    known = set()
    auths = set()
    print(len(females))
    print(len(males))
    print("Mediani, Mohammed" in males)
    pars = HTMLParser()
    with open(ids_path,"r", encoding="utf-8") as f:
        paper_data = f.read().split("\n\n")
        for idx,paper in enumerate(paper_data):
            values = paper.split("\n")[:len(fields)-1]

            values = dict(zip(fields,[re.search(r'{(.*?)}',s).group(1) for s in values]+[[]]))
            
            values["authors"] = values["authors"].split("; ")
            for auth in values["authors"]:  
                auth = auth.strip() 
                auth = pars.unescape(auth)
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
                    new_unkown.add(auth)
                values["genders"].append(gender)
            #dic.append(values)
            prev = values
            #if idx==5:
            #    break
        print(len(auths))
        print(len(known))
        print(len(new_unkown))
          
    #df = pd.DataFrame(dic)#.set_index(["id"])
    with open(os.path.join(os.environ["AAN_DIR"],"aclr_unknown2.txt"),"w", encoding="utf-8") as f:
        f.write("\n".join(new_unkown))



def main():
    #nc = NameClassifier()
    #print(nc.classify_unknown_from_known_stats())
    map_titles()

 
 
if __name__ == '__main__':
    main()
