from _name_classification.nametools import process_str
# Request headers.
########### Python 3.6 #############
import http.client, urllib.request, urllib.parse, urllib.error, base64, requests, json
import os
import re
###############################################


####################################    
class affiliations():


	def __init__(self):

		ids_path = os.path.join(os.environ["AAN_DIR"],"release/2014/author_ids.txt")
		aff_path = os.path.join(os.environ["AAN_DIR"],"release/2014/author_affiliation_pairs.txt")
		id_to_aff= dict()
		self.name_to_aff = dict()
		with open(aff_path,"r") as f:
			lines = f.read().split("\n")
			for line in lines:
				if(len(re.split("\s+",line,1))<2):
					continue
				i, aff = re.split("\s+",line,1)
				aff = aff.split(",")[0]
				id_to_aff[i] = aff

		with open(ids_path,"r") as f:
			lines = f.read().split("\n")
			for line in lines:
				if(len(re.split("\s+",line,1))<2):
					continue
				i,name = re.split("\s+",line,1)
				a = id_to_aff.get(i,-1)
				if a is not -1:
					self.name_to_aff[name] = a


	def find_aff(self,name):
		return self.name_to_aff.get(name,-1)

