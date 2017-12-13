
import os
from affiliations import affiliations
from lookup import BingImageSearch
from faces import BingFaceDetection
from nametools import process_str

class ClassifyFace():
	def __init__(self):
		self.aff = affiliations()
		self.n_results = 4
		self.priorities = [0.5, 0.30, 0.10, 0.10]

	def get_classif(self,name):
		a = self.aff.find_aff(name)
		search = name
		# if a is not -1:
		# 	search += a
		# 	print("SEARCH: ",search)


        #RESEARCH
		try:
			#trust this more
			values = BingImageSearch(search + " research")
			url = values[0]["contentUrl"]
			ok, gender = BingFaceDetection(url)
			if gender:
				return url, gender
		except:
			pass

		#UNIVERSITY

		try:
			#trust this more
			values = BingImageSearch(search + " university")
			url = values[0]["contentUrl"]
			ok, gender = BingFaceDetection(url)
			if gender:
				return url, gender
		except:
			pass


		try:
			#trust this more
			values = BingImageSearch(search + " edu")
			url = values[0]["contentUrl"]
			ok, gender = BingFaceDetection(url)
			if gender:
				return url, gender
		except:
			pass


        #JUST NAME
		try:
			values = BingImageSearch(search)
			if not values:
				return [None,None]
			#trust first 2 results more
			for i in range(min(3,len(values))):
				url = values[i]["contentUrl"]
				ok, gender = BingFaceDetection(url)
				if gender:
					return url, gender

		except Exception as e:
			print('Error: ',search)
			print(e)
			return [None, None]
		return [None, None]




# cf = ClassifyFace()

# female_paths = [os.path.join(os.environ["AAN_DIR"], "save/",
#         f) for f in ["machine_females.txt"]]


# females = set()

# for file in female_paths:
# 	with open(file, 'r', encoding = "utf-8") as f:
# 		females.update(map(lambda x:  process_str(x), f.read().split("\n")))


# for f in females:
# 	url, g = cf.get_classif(f)
# 	print(f," ",g," ", url)