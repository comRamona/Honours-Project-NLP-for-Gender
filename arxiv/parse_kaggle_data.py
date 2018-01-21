from os.path import join
from os import environ
import pandas

with open(join(environ["AAN_DIR"], 'arxiv_data.csv'), 'r') as file:
    data = pandas.read_csv(file)

print(data)
