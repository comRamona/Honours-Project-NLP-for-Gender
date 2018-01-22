from gensim.models.ldamodel import LdaModel
from gensim.models import LdaMulticore
from gensim.corpora import MmCorpus
from gensim.corpora import Dictionary
from numpy.random import seed
import numpy as np
import random
import logging

seed(1)
logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.INFO)
logging.root.level = logging.INFO
v = 8
corpus = MmCorpus('acl_bow8.mm')
dictionary = Dictionary.load('dict' + str(v) + '.pkl')
_ = dictionary[0]
id2word = dictionary.id2token
del dictionary

train_size = int(round(len(corpus)*0.8))
train_index = sorted(random.sample(range(len(corpus)), train_size))
test_index = sorted(set(range(len(corpus)))-set(train_index))
train_corpus = [corpus[i] for i in train_index]
test_corpus = [corpus[j] for j in test_index]

# model = models.LdaMulticore(corpus=corpus, workers=None, id2word=id2word, num_topics=100, iterations=500, passes=1000, alpha="auto", eta="auto")
   
model = LdaModel(corpus=corpus, id2word=id2word, num_topics=100, iterations=500, passes=1000, alpha="auto", eta="auto")
perplex = model.bound(test_corpus) # this is model perplexity not the per word perplexity
print("Total Perplexity: %s" % perplex)


per_word_perplex = np.exp2(-perplex / number_of_words)
print("Per-word Perplexity: %s" % per_word_perplex)
   
model.save(data_path + 'lda' + str(v) + '_training_corpus.lda')

# lda_model = LdaModel(corpus, id2word=id2word, num_topics=100, passes=1000, iterations=500, alpha="auto", eta="auto")
# lda_model.save("model" + str(v) + ".pkl")

# lda = gensim.models.ldamodel.LdaModel.load('lda.model')
