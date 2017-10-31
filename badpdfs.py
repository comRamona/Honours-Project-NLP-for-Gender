import langid 
from langid.langid import LanguageIdentifier, model
from indexes import ACL_metadata
from tqdm import tqdm


acl = ACL_metadata()
identifier = LanguageIdentifier.from_modelstring(model, norm_probs=True)

bad_pdfs = []
all_pdfs = []
for train_file in tqdm(acl.train_files):
    with open(train_file) as f:
        txt = f.read()
        l, c = identifier.classify(txt)

        all_pdfs.append((train_file,l,c))
        fid = acl.get_id(train_file)
        if(l!="en" or c < 1.0):
             bad_pdfs.append((fid,l,c))

import _pickle as pkl 
with open("bad_pdfs.pkl","wb") as f:
   pkl.dump(bad_pdfs,f)