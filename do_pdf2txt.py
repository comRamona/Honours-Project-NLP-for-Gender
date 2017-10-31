import pdftotext
import _pickle as pkl 
import os
from tqdm import tqdm

with open("bad_pdfs.pkl","rb") as f:
    ids = pkl.load(f)

for i in tqdm(ids):
    file_path = os.path.join(os.environ["AAN_DIR"],"papers_pdf/{0}.pdf".format(i))
    if not os.path.isfile(file_path):
        path = "http://aclweb.org/anthology/{0}".format(i)
        try:
            wget.download(path, out=file_path)
        except:
            print("Couldn't find file ",i)


    with open(file_path, "rb") as f:
        pdf = pdftotext.PDF(f)

    with open(os.path.join(os.environ["AAN_DIR"],"papers_text/{0}.pdf".format(i)),"w") as f:
        f.write(pdf.read_all())

