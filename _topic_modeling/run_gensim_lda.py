from gensim.models.ldamodel import LdaModel
from gensim.corpora import MmCorpus
from gensim.corpora import Dictionary
from numpy.random import seed
import logging

seed(1)
logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.INFO)
logging.root.level = logging.INFO

corpus = MmCorpus('acl_bow.mm')
dictionary = Dictionary.from_corpus(corpus)
_ = dictionary[0]
id2word = dictionary.id2token
del dictionary
lda_model = LdaModel(corpus, id2word=id2word, num_topics=100, passes=1000, iterations=100, alpha="auto", eta="auto")
lda_model.save("model500.pkl")

# lda = gensim.models.ldamodel.LdaModel.load('lda.model')
