from gensim.corpora import MmCorpus
import _pickle as pkl
import gensim
from numpy.random import seed
from os.path import join
from os import environ
import logging

seed(1)
logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.INFO)
logging.root.level = logging.INFO


class Loader():

    def __init__(self):

        self.corpus = MmCorpus(join(environ["AAN_DIR"], '../acl_bow.mm'))
        with open("../dict.pkl", "rb") as file:
            self.dic = pkl.load(file)
        self.id2word = self.dic.id2token
        self.mallet_model = gensim.models.wrappers.LdaMallet.load(join(environ["AAN_DIR"], '../malltepy'))
