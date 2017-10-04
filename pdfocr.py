from wand.image import Image
from PIL import Image as PI
import pyocr
import pyocr.builders
import io
import wget
import sys
import os
from time import time

def get_test(fn="W04-0205"):
    tool = pyocr.get_available_tools()[0]
    lang = tool.get_available_languages()[1]

    req_image = []
    final_text = []

    #get pdf
    file_path = os.path.join(os.environ["AAN_DIR"],"papers_pdf/{0}.pdf".format(fn))
    if not os.path.isfile(file_path):
        path = "http://aclweb.org/anthology/{0}".format(fn)
        wget.download(path, out=file_path)

    #convert to jpeg
    t0 = time()
    image_pdf = Image(filename=file_path,resolution=300)
    image_jpeg = image_pdf.convert('jpeg')

    print("done converting to jpeg %0.3fs." % (time() - t0))

    t1 = time()

    for img in image_jpeg.sequence:
        img_page = Image(image=img)
        req_image.append(img_page.make_blob('jpeg'))
  
    print("done req image %0.3fs." % (time() - t1))

    with open(os.path.join(os.environ["AAN_DIR"],"papers_ocr/{0}.txt".format(fn)), "w") as text_file:

        for img in req_image: 

            txt = tool.image_to_string(
                PI.open(io.BytesIO(img)),
                lang=lang,
                builder=pyocr.builders.TextBuilder()
            )

            text_file.write(str(txt))




def main():

    
    get_test(sys.argv[1]) if len(sys.argv)>1 else get_test()
 
 
if __name__ == '__main__':
    main()
