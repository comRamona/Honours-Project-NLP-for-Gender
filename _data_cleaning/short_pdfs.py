from metadata.metadata import ACL_metadata
from tqdm import tqdm
from _storage.storage import FileDir

acl = ACL_metadata()
fd = FileDir()
bad_pdfs = []
all_pdfs = []
lens = []
tf = acl.train_files
print(len(tf))
for train_file in tqdm(tf):
    with open(train_file) as f:
        txt = f.read()
        tokens = txt.split()
        if len(tokens) < 300:
            fid = acl.get_id(train_file)
            bad_pdfs.append((fid, len(tokens)))

fd.save_pickle(bad_pdfs, "short_pdfs")
