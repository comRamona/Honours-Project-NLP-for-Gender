import pdftotext
import _pickle as pkl 
import os
from tqdm import tqdm
import wget

with open("bad_pdfs.pkl","rb") as f:
    ids = pkl.load(f)

for idx in tqdm(ids):
    i = idx[0].strip()
    file_path = os.path.join(os.environ["AAN_DIR"],"papers_pdf/{0}.pdf".format(i))
    if not os.path.isfile(file_path):
        path = "http://aclweb.org/anthology/{0}".format(i)
        try:
            wget.download(path, out=file_path)
        except:
            print("Failed to download",i)

     


    with open(file_path, "rb") as f:
        try:
            pdf = pdftotext.PDF(f)
        except:
            print("Failed to convert",i)

    with open(os.path.join(os.environ["AAN_DIR"],"papers_text2/{0}.txt".format(i)),"w") as f:
        f.write(pdf.read_all())

