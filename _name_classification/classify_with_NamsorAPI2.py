# generated by http://restunited.com
# for any feedback/issue with the code, please contact support{at}restunited.com

# initialize the API client

import base64
import Namsor
from io import open
import re
from collections import Counter, defaultdict
import os
from pprint import pprint
import unidecode
import HTMLParser

html = HTMLParser.HTMLParser()

api_client = Namsor.swagger.ApiClient(api_server="https://api.namsor.com/onomastics/api/json")

first_name = "John"  # Firstname
last_name = "Smith"  # Lastname
country_iso2 = ""  # Countryiso2
x_client_version = "namsor_restunited_v0.21.x"  # Library Version (Client)
x_channel_secret = "63m6Yx0zLNAM33krdm3SORekGn8CFB"  # Your API Key (Secret)
x_channel_user = "namsor.com/com.ramona@yahoo.com/612002"  # Your API Channel (User)

gendre_api = Namsor.GendreApi(api_client)

    
    # return Genderize (model)
        

    # To display structured information of a variable, please use var_dump: pip install var_dump
    # from var_dump import var_dump
    # var_dump(response)
    # print(response.gender, response.scale)

machine_females = open(os.path.join(os.environ["AAN_DIR"],"machine_femalesNAM3.txt"),"w", encoding="utf-8")
machine_males = open(os.path.join(os.environ["AAN_DIR"],"machine_malesNAM3.txt"),"w", encoding="utf-8")
result_unknown = open(os.path.join(os.environ["AAN_DIR"],"NAM_UNK3.txt"),"w", encoding="utf-8")

with open(os.path.join(os.environ["AAN_DIR"],"aclr_unknown_after_2009.txt"),"r", encoding="utf-8") as f:
    unknown_names = list(map(lambda x: x.strip(), f.read().split("\n")))
    males=0
    females=0
    regex = re.compile(r"\w+\.", re.IGNORECASE)
    new_unk = set()
    i = 0
    for name in unknown_names[5:50]:
    	i += 1
    	print(i)
    	sn = name.strip()
        name = unidecode.unidecode(html.unescape(name))
        try:
            fn = name.split(",")[1].strip().split()[0]
            ln = name.split(",")[0].strip()
            no_initials = regex.sub("",fn).strip()
            response = gendre_api.extract_gender(no_initials, ln, country_iso2, x_client_version, x_channel_secret, x_channel_user)
            g = response.gender
            p = float(response.scale)
            res = sn + "; " + unicode(p) + "\n"
            print(res)
            if abs(p) < 0.8:
                result_unknown.write(res)
                continue
            if g == "male":
                males += 1
                machine_males.write(res)
                #print(name," M ",p)
            elif g == "female":
                females +=1
                machine_females.write(res)
                #print(name,"F ",p)
            else:
                result_unknown.write(res)
                #new_unk.add(name)
        except:
            result_unknown.write(res)
        if(i == 980):
        	break

     

    #result_unknown.write("\n".join(new_unk))
    #print(males,females,len(new_unk), len(list(unknown_names)))

