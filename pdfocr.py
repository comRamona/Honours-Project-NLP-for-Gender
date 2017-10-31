from wand.image import Image
from PIL import Image as PI
import pyocr
import pyocr.builders
import io
import wget
import sys
import os
from time import time
from tqdm import tqdm
import _pickle as pkl



def get_test(fn):
    tool = pyocr.get_available_tools()[0]
    lang = tool.get_available_languages()[1]

    req_image = []
    final_text = []
    
    file_path = os.path.join(os.environ["AAN_DIR"],"papers_pdf/{0}.pdf".format(fn))
   
    #convert to jpeg
    image_pdf = Image(filename=file_path,resolution=300)
    image_jpeg = image_pdf.convert('jpeg')


    for img in image_jpeg.sequence:
        img_page = Image(image=img)
        req_image.append(img_page.make_blob('jpeg'))

    with open(os.path.join(os.environ["AAN_DIR"],"papers_ocr/{0}.txt".format(fn)), "w") as text_file:

        for img in req_image: 

            txt = tool.image_to_string(
                PI.open(io.BytesIO(img)),
                lang=lang,
                builder=pyocr.builders.TextBuilder()
            )

            text_file.write(str(txt))


def ocr_bad_files():
    with open("bad_pdfs.pkl","rb") as f:
        ids = pkl.load(f)

    for idx in tqdm(ids):
        i = idx[0].strip()
        file_path = os.path.join(os.environ["AAN_DIR"],"papers_pdf/{0}.pdf".format(i))
        if not os.path.isfile(file_path):
            path = "http://aclweb.org/anthology/{0}.pdf".format(i)
            try:
                wget.download(path, out=file_path)
            except:
                print("Failed to download",i)

         
        try:
            get_test(i)
        except Exception as e:
            print(e)
       





def main():

    #ocr_bad_files()
    get_test("E03-1022")
 
 
if __name__ == '__main__':
    main()
