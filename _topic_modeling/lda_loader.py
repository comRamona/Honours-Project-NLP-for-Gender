from gensim.corpora import MmCorpus
import _pickle as pkl
import gensim
from numpy.random import seed
from os.path import join
from os import environ
import logging
from _storage.storage import FileDir

seed(1)
logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.INFO)
logging.root.level = logging.INFO


class Loader():

    def __init__(self):
        
        fd = FileDir()
        self.corpus = MmCorpus(join(fd.models,'acl_bow10.mm'))
        self.dic = fd.load_pickle("dict10")
        self.doc_ids = fd.load_pickle("doc10_ids")
        self.doc_topics = fd.load_pickle("doc_topics_gensim10")
        self.topic_corresp = fd.load_pickle("topic_corresp10_edit")
        self.id2word = self.dic.id2token
        self.model = gensim.models.ldamodel.LdaModel.load(join(fd.models, "ldaseed310lda"))