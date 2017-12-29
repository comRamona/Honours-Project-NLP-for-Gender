import langid 
from langid.langid import LanguageIdentifier, model
from metadata.metadata import ACL_metadata
from tqdm import tqdm
import os
from os import listdir
from os.path import isfile, join
from os import environ

acl = ACL_metadata()
identifier = LanguageIdentifier.from_modelstring(model, norm_probs=True)

bad_pdfs = []
all_pdfs = []
train_dirpath = os.path.join(os.environ["AAN_DIR"],"papers_text2")
tf = [join(environ["AAN_DIR"],"papers_text/{0}".
    format(fn)) for fn in listdir(join(environ["AAN_DIR"],"papers_text2/")) if isfile(join(train_dirpath, fn)) and "txt" in fn]
print(len(tf))
for train_file in tqdm(tf):
    with open(train_file) as f:
        txt = f.read()
        l, c = identifier.classify(txt)

        all_pdfs.append((train_file,l,c))
        fid = acl.get_id(train_file)
        if(l!="en" or c < 1.0):
             bad_pdfs.append((fid,l,c))

import _pickle as pkl 
with open("bad_pdfs2.pkl","wb") as f:
   pkl.dump(bad_pdfs,f)