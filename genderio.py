import io as _io
import os as _os
import nltk as _nltk
import random as _random
import pickle as _pickle
import urllib.request as _request
import collections as _collections

from zipfile import ZipFile as _zp

PATH = './gender_prediction/'
URL = 'https://github.com/clintval/gender_predictor/raw/master/names.zip'


class GenderPredictor():
    def __init__(self):
        counts = _collections.Counter()
        self.males = set()
        self.females = set()
        for name_results in self._get_USSSA_data:
            name, male_counts, female_counts = name_results



            if male_counts == female_counts:
                continue

            if male_counts > female_counts:
                self.males.add(name)

            else:
                self.females.add(name)


            # if male_counts <= 2 and female_counts >= 2:
            #     self.females.add(name)
            # elif female_counts <= 2 and male_counts >=2 :
            #     self.males.add(name)
            

    @property
    def _get_USSSA_data(self):
        if _os.path.isdir(PATH) is False:
            _os.makedirs(PATH)

        if _os.path.exists(PATH + 'names.pickle') is False:
            names = _collections.defaultdict(lambda: {'M': 0, 'F': 0})
            print('names.pickle does not exist... creating')

            if _os.path.exists(PATH + 'names.zip') is False:
                print('names.zip does not exist... downloading')
                _request.urlretrieve(URL, PATH + 'names.zip')

            with _zp(PATH + 'names.zip') as infiles:
                for filename in infiles.namelist():
                    with _io.TextIOWrapper(infiles.open(filename)) as infile:
                        for row in infile:
                            name, gender, count = row.strip().split(',')
                            names[name.upper()][gender] += int(count)

            data = [(n, names[n]['M'], names[n]['F']) for n in names]

            with open(PATH + 'names.pickle', 'wb') as handle:
                _pickle.dump(data, handle, _pickle.HIGHEST_PROTOCOL)
                print('names.pickle saved')
        else:
            with open(PATH + 'names.pickle', 'rb') as handle:
                data = _pickle.load(handle)
                print('import complete')
        return(data)