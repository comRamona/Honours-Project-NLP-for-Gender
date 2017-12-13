import unidecode
import html
import re

def process_str(input_str):
		names = map(lambda x: re.sub("\W","",unidecode.unidecode(html.unescape(x)).lower()).strip(), 
		input_str.split(",",2))

		return ",".join(names).title()
