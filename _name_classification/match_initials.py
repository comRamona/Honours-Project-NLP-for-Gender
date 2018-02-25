import re
def is_initials(name, sp=", "):
    
    fn = name.split(sp)
    if len(fn) < 2:
        return True
    fn = fn[1].strip()
    regex = re.compile(r"\w+\.", re.IGNORECASE)
    no_initials = regex.sub("", fn).strip()
    if len(no_initials) < 2:
        return True
    return False
        
def init_match(inits, name):
    inits = inits.replace("Dr.","")
    inits = inits.strip()
    if(len(inits) == 0):
        return 0
    name = name.strip()
    inits_split = inits.split(" ")
    name_split = name.split(" ")
    if len(inits_split) == len(name_split):
        match = True
        for idx, i in enumerate(inits_split):
            if i.strip()[0] != name_split[idx].strip()[0]:
                match = False
        if match == True:
            return 1 #confident match
    if inits[0] == name_split[0]:
        return 2 # maybe match
    inits_set = set()
    name_set = set()
    for letter in inits:
        if letter.isupper():
            inits_set.add(letter)
    for letter in name_set:
        if letter.isupper():
            name_set.add(letter)
    if inits_set == name_set:
        return 1 # confident match
    for letter in inits_set:
        if letter in name_set:
            return 3 # maybee
    return 0 #no match

from collections import defaultdict
male_last_names = defaultdict(list)
for name in known_m:
    if len(name.split(", ")) < 2:
        continue
    last, first = name.split(", ")
    male_last_names[last].append(first)
    
female_last_names = defaultdict(list)
for name in known_f:
    if len(name.split(", ")) < 2:
        continue
    last, first = name.split(", ")
    female_last_names[last].append(first)

def best_match(name):
    if len(name.split(", ")) < 2:
        return (None, None)
    last, first = name.split(", ")
    m = last in male_last_names
    f = last in female_last_names
    if m and not f:
        names = male_last_names[last]
        for n in names:
            mtch = init_match(first, n)
            if mtch != 0:
                return (last + ", " + n, Gender.male)
       
    if f and not m:
        names = female_last_names[last]
        for n in names:
            mtch = init_match(first, n)
            if mtch != 0:
                return (last + ", " + n, Gender.male)
    if f and m:
        
        match_f = 0
        match_m = 0
        names = male_last_names[last]
        best_match = (None, None)
        for n in names:
            mtch = init_match(first, n)
            if(mtch > match_m):
                match_m = mtch
                best_match = (last + ", " + n, Gender.male)
        names = female_last_names[last]
        for n in names:
            mtch = init_match(first, n)
            if(mtch > match_f):
                match_f = mtch
                if mtch > match_m:
                    best_match = (last + ", " + n, Gender.female)
        if match_f > match_m:
            return best_match
        if match_m > match_f:
            return best_match
    return (None, None)


c=['authors', 'genders', 'title', 'venue', 'year']
gender_df = pd.DataFrame(columns=c)
k = 0
for row in df.iterrows():
    new_entry = dict()
    for col in ["venue", "title", "year"]:
        new_entry[col] = row[1][col]
    new_entry["id"] = row[1].name
    authors = row[1]["authors"]
    genders = []
    correct_authors = []
    for a in authors:
        if is_initials(a,","):
            #print(a)
            #print(best_match(a))
            best_m, g = best_match(a)
            if best_m != None:
                correct_authors.append(best_m)
                genders.append(g)
                k += 1
                #print(a, best_m)
            else:
                correct_authors.append(a)
        else:
            correct_authors.append(a)
            if(a in known_m):
                genders.append(Gender.male)
            elif a in known_f:
                genders.append(Gender.female)
            else:
                genders.append(Gender.unknown)
    new_entry["authors"] = correct_authors
    new_entry["genders"] = genders
    gender_df = gender_df.append(new_entry, ignore_index=True)
gender_df.set_index("id")
print(k)   
