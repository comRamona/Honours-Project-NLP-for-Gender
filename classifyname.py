# -*- coding: utf-8 -*-
import os
from io import open
import re
from collections import Counter, defaultdict
import sexmachine.detector as gd
from cleanname import clean
from metadata import Gender
import html
from classifyface import ClassifyFace
import codecs
from urllib.request import Request, urlopen  # Python 3



class NC():

    def __init__(self):
        self.gender_machine = gd.Detector()
        self.custom_dict = {} #self.parseCustomDataSet()
        with open(os.path.join(os.environ["AAN_DIR"],"save","indianmale.txt"),"r", encoding="utf-8") as f:
            self.indian_boys = set(map(lambda x: x.strip(), f.read().split("\n")))

        with open(os.path.join(os.environ["AAN_DIR"],"save","indianfemale.txt"),"r", encoding="utf-8") as f:
            self.indian_girls = set(map(lambda x: x.strip(), f.read().split("\n")))

        with open(os.path.join(os.environ["AAN_DIR"],"save","indianunisex.txt"),"r", encoding="utf-8") as f:
            indian_names = set(map(lambda x: x.strip(), f.read().split("\n")))
            self.indian_girls =  self.indian_girls.difference(indian_names)
            self.indian_boys =  self.indian_boys.difference(indian_names)

        self.manual_girls= ["Marion","Stéphane","Whitney","Amy","María",
        "Clara","Elisa", "Maria","Diana", "Carmen", "Ramona", "Anne", "Octavia-Maria","Kelly","Darnes"]

        self.manual_boys = ["Will","Sandeep","Ben","Jesus","José","Jose","Deepak","Sandeep",
        "Javier","Ritwik","Gaël","Kartik","FranÃ§ois","Adrian", "Adri?","Michal", "Dan","Florin","Mihai", 
        "Christian","Nate","João","Jan","Ilia","Vishal","Jesús","Ronan", "Karel", "Lluís"]


        self.namsor_dict = {}
        with open(os.path.join(os.environ["AAN_DIR"],"save","namresults.txt"),"r", encoding="utf-8") as f:
            unknown_names = f.read().split("\n")
          
            p = re.compile("\(u.(.+)., '(.*)', (.*)\)")

            for line in unknown_names:

                if not line: continue
                
                m = p.match(line)
               

                name = html.unescape(m.group(1))
                gender = m.group(2).strip()
                scale = float(m.group(3))
                if(abs(scale) < 0.4): 
                    continue
                if gender == "female":
                    self.namsor_dict[name] = Gender.female
                elif gender == "male":
                    self.namsor_dict[name] = Gender.male

        self.known_fn = dict()


        self.cf = ClassifyFace()



    def classify_name(self,name, bing=True):

        escape_name = html.unescape(name).title()

        first_name_no_initials = self.get_first_name(escape_name)
    
        if len(first_name_no_initials) <= 2:
            return (Gender.unknown, " ", escape_name, " too short")

        if first_name_no_initials in self.known_fn:
            return (self.known_fn[first_name_no_initials], " know it already")
        else:
            g = self.first_name_methods(first_name_no_initials)
            if g[0] != Gender.unknown:
                self.known_fn[first_name_no_initials] = g[0]
                return g
           
        g = self.classify_ova(escape_name)
        if g != Gender.unknown:
            return (g, escape_name + " found as Bulgarian")


        g = self.namsor_dict.get(name.strip(),Gender.unknown)
        if g != Gender.unknown:
            return (g, name + " found with Namsor")

        if bing:

            try:
                gp = self.determineFromGPeters(first_name_no_initials, 1.2)
                msg, g= self.cf.get_classif(escape_name)
                if g == "male" and gp != Gender.female:
                    return (Gender.male, str(msg) + " " + escape_name + " Bing")
                elif g == "female" and gp != Gender.male:
                    return (Gender.female, str(msg) + " " + escape_name + " Bing")
                else:
                    return (Gender.unknown, escape_name + " gp and bing disagree")

            except Exception as e:
                print(e,name)


        return (Gender.unknown, name + " can't classify")


    def first_name_methods(self, first_name_no_initials):

        if first_name_no_initials in self.manual_girls:
            return (Gender.female, first_name_no_initials + " manual")
        if first_name_no_initials in self.manual_boys:
            return (Gender.male, first_name_no_initials + " manual")

        g = self.classify_w_gender_machine(first_name_no_initials)
        if g != Gender.unknown:
            return (g, first_name_no_initials + " found with gender_machine")

        g = self.classify_indian(first_name_no_initials)
        if g != Gender.unknown:
            return (g, first_name_no_initials + " found as indian")

        # g = self.search_custom_dict(first_name_no_initials)
        # if g != Gender.unknown:
        #     return (g, re.sub("[^A-Za-z]", "", clean(first_name_no_initials).lower()) + " found in custom_dict")

        g = self.determineFromGPeters(clean(first_name_no_initials))
        if g != Gender.unknown:
            return (g, first_name_no_initials + " found with gPeters")
        return (Gender.unknown, "")

    def search_custom_dict(self,first_name_no_initials):
        g = self.custom_dict.get(re.sub("[^A-Za-z]", "", clean(first_name_no_initials).lower()), Gender.unknown)
        return g
            


    def get_first_name(self,name):
        if len(name.strip().split(",")) < 2:
            return ""
        first_name = name.split(",")[1].strip()
        regex = re.compile(r"\w+\.", re.IGNORECASE)
        no_initials = regex.sub("",first_name).strip()
        return no_initials
       

    def classify_ova(self,name):
        ln = name.split(",")[0].strip()
        if(ln[-2:]=="ov"): 
            return Gender.male
        if(ln[-3:]=="ova"): 
            return Gender.female
        return Gender.unknown



    def parseCustomDataSet(self, fileName = "dict2.txt"):
        names = {}
        f     = codecs.open(fileName, 'r', encoding='iso8859-1').read()
        f     = set(f.split("\n"))

        for person in f:
            try:
                separate = person.split(',')
                name     = separate[0].lower()
                if name in names:
                    gender = Gender.unknown
                elif int(separate[1]) == 0:
                    gender  = Gender.male
                elif int(separate[1]) == 1:
                    gender  = Gender.female
                else:
                    gender  = Gender.unknown

                names[name] = gender
            except:
                pass

        return names



    def classify_w_gender_machine(self, name):
        g = self.gender_machine.get_gender(name)
        if g == "male":
            return Gender.male
        elif g == "female":
            return Gender.female
        else:
            return Gender.unknown


    def _cut(self, start, end, data):
        rez = []
        one = data.split(start)

        for i in range(1, len(one)):
            two = one[i].split(end)

            rez.append(two[0])

        return rez[0] if len(rez) == 1 else rez


    def determineFromGPeters(self, name, prob = 4):
    
        try:
            req   = Request('http://www.gpeters.com/names/baby-names.php?name=' + name)
            req.add_header('User-agent', 'Mozilla/5.0')
            get    = str(urlopen(req).read())

            findGender  = get.split("<b>It\\'s a")
            if len(findGender) < 2:
                return Gender.unknown
            findGender = findGender[1].split("</b>")[0]

            findGender  = Gender.male if "boy" in findGender else Gender.female
            probability = (str(get).split("Based on popular usage, it is <b>")[1]).split(" times more common")[0]
            probability = float(probability)

            if probability < prob:
                gender = Gender.unknown
            else:
                gender = findGender
            return gender
        except:
            pass

        return Gender.unknown

    def classify_indian(self, name):
      
        if name in self.indian_boys:
            return Gender.male
        elif name in self.indian_girls:
            return Gender.female
        else:
            return Gender.unknown
