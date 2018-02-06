import _pickle as pkl 
import os
from chicksexer import predict_gender

with open(os.path.join(os.environ['AAN_DIR'], "save", "known_names.pkl"), "rb") as file:
	dicty = pkl.load(file)

for x in dicty:
	print(x)