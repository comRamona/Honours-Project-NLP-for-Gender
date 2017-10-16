import sexmachine.detector as gender
import os
from io import open
import re


#1
def gender_machine():
    d = gender.Detector()

    machine_females = open(os.path.join(os.environ["AAN_DIR"],"machine_females.txt"),"w", encoding="utf-8")
    machine_males = open(os.path.join(os.environ["AAN_DIR"],"machine_males.txt"),"w", encoding="utf-8")
    machine_unknown = open(os.path.join(os.environ["AAN_DIR"],"machine_unknown.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"new_unknown.txt"),"r", encoding="utf-8") as f:
        unknown_names = map(lambda x: x.strip(), f.read().split("\n"))
        males=0
        females=0
        unk=0
        total=0
        regex = re.compile(r"\w+\.", re.IGNORECASE)
        for name in unknown_names:
            name = name.strip()
            try:
                total+=1
                fn = name.split(",")[1].strip()
                no_initials = regex.sub("",fn).strip()
                gn = d.get_gender(no_initials)
                if gn == "male":
                    males += 1
                    machine_males.write(name + "\n")
                elif gn == "female":
                    females +=1
                    machine_females.write(name + "\n")
                else:
                    unk += 1
                    machine_unknown.write(name + "\n")
            except:
                pass

        print(males,females,unk,total)

#3
def manual_list():
    mfemales = ["Clara","Maria","Diana", "Carmen", "Ramona", "Anne", "Octavia-Maria"]
    mmales = ["Adrian", "Dan","Florin","Mihai", "Christian"]

    machine_females = open(os.path.join(os.environ["AAN_DIR"],"machine_females.txt"),"a+", encoding="utf-8")
    machine_males = open(os.path.join(os.environ["AAN_DIR"],"machine_males.txt"),"a+", encoding="utf-8")
    machine_unknown3 = open(os.path.join(os.environ["AAN_DIR"],"machine_unknown3.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"machine_unknown2.txt"),"r", encoding="utf-8") as f:
        unknown_names = map(lambda x: x.strip(), f.read().split("\n"))
        males=0
        females=0
        unk=0
        total=0
        regex = re.compile(r"\w+\.", re.IGNORECASE)
        for name in unknown_names:
            name = name.strip()
            try:
                total+=1
                fn = name.split(",")[1].strip().split()[0]
                no_initials = regex.sub("",fn).strip()
                if no_initials in mmales:
                    males += 1
                    machine_males.write(name + "\n")
                elif no_initials in mfemales:
                    females +=1
                    machine_females.write(name + "\n")
                else:
                    unk += 1
                    machine_unknown3.write(name + "\n")
            except:
                pass

        print(males,females,unk,total)


#4
def manual_set():
   
    machine_set = open(os.path.join(os.environ["AAN_DIR"],"machine_set.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"machine_unknown3.txt"),"r", encoding="utf-8") as f:
        unknown_names = map(lambda x: x.strip(), f.read().split("\n"))
        unk = set()
        for name in unknown_names:
            name = name.strip()
            unk.add(name)

        for name in unk:
            machine_set.write(name+"\n")

        print(len(unk))


#2
def gender_bulgarian():

    bulgarian_females = open(os.path.join(os.environ["AAN_DIR"],"machine_females.txt"),"a+", encoding="utf-8")
    bulgarian_males = open(os.path.join(os.environ["AAN_DIR"],"machine_males.txt"),"a+", encoding="utf-8")
    machine_unknown2 = open(os.path.join(os.environ["AAN_DIR"],"machine_unknown2.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"machine_unknown.txt"),"r", encoding="utf-8") as f:
        unknown_names = map(lambda x: x.strip(), f.read().split("\n"))
        males=0
        females=0
        unk=0
        total=0
        for name in unknown_names:
            name = name.strip()
            try:
                total+=1
                ln = name.split(",")[0].strip()
                gn = "unk"
                if(ln[-2:]=="ov"): gn ="male"
                if(ln[-3:]=="ova"): gn ="female"
             
                if gn == "male":
                    males += 1
                    bulgarian_males.write(name + "\n")
                elif gn == "female":
                    females +=1
                    bulgarian_females.write(name + "\n")
                else:
                    unk += 1
                    machine_unknown2.write(name + "\n")
            except:
                pass

        print(males,females,unk,total)


#5
def map_us_census():

    census_path = os.path.join(os.environ["AAN_DIR"],
        "US_CENSUS_FOMO")
 
    cfemales = set()
    cmales = set()

    with open(census_path,"r",encoding="utf-8") as f:
        data = f.read().split("\n")
        for line in data:
        	gender, lastname, name = line.split()
        	if gender == "FO":
        		cfemales.add(name)
        	elif gender == "MO":
        		cmales.add(name)

    print(len(cfemales), len(cmales))


    machine_females = open(os.path.join(os.environ["AAN_DIR"],"machine_females.txt"),"a+", encoding="utf-8")
    machine_males = open(os.path.join(os.environ["AAN_DIR"],"machine_males.txt"),"a+", encoding="utf-8")
    machine_set2 = open(os.path.join(os.environ["AAN_DIR"],"machine_set2.txt"),"w", encoding="utf-8")

    with open(os.path.join(os.environ["AAN_DIR"],"machine_set.txt"),"r", encoding="utf-8") as f:
        unknown_names = map(lambda x: x.strip(), f.read().split("\n"))
        males=0
        females=0
        unk=0
        total=0
        for name in unknown_names:
            name = name.strip()
            try:
                total+=1
                no_initials = name.split(",")[1].strip("-").split()[0]
                print(no_initials)
                if no_initials in cmales:
                    males += 1
                    machine_males.write(name + "\n")
                elif no_initials in cfemales:
                    females +=1
                    machine_females.write(name + "\n")
                else:
                    unk += 1
                    machine_set2.write(name + "\n")
            except:
                pass

        print(males,females,unk,total)


if __name__ == '__main__':
    # gender_machine()
    # gender_bulgarian()
    # manual_list()
    # manual_set()
    map_us_census()
    