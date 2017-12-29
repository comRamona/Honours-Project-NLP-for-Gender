
# coding: utf-8

# In[1]:


# # Topic extraction with Non-negative Matrix Factorization and Latent Dirichlet Allocation
#
#
# This is an example of applying :class:`sklearn.decomposition.NMF` and
# :class:`sklearn.decomposition.LatentDirichletAllocation` on a corpus
# of documents and extract additive models of the topic structure of the
# corpus.  The output is a list of topics, each represented as a list of
# terms (weights are not shown).
#
# Non-negative Matrix Factorization is applied with two different objective
# functions: the Frobenius norm, and the generalized Kullback-Leibler divergence.
# The latter is equivalent to Probabilistic Latent Semantic Indexing.
#
# The default parameters (n_samples / n_features / n_components) should make
# the example runnable in a couple of tens of seconds. You can try to
# increase the dimensions of the problem, but be aware that the time
# complexity is polynomial in NMF. In LDA, the time complexity is
# proportional to (n_samples * iterations).
#
#
#
import logging
import _pickle as pkl
import pyLDAvis.gensim
import numpy as np

rng = np.random.RandomState(10102016)
np.random.seed(18101995)
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = [logging.StreamHandler()]


def dehyphenate(s):
    return s.replace('-\n', '').lower()


def print_top_words(model, feature_names, n_top_words):
    for topic_idx, topic in enumerate(model.components_):
        message = "Topic #%d: " % topic_idx
        message += " ".join([feature_names[i]
                             for i in topic.argsort()[:-n_top_words - 1:-1]])
        print(message)
    print()


with open("../models/ldamodel2017-11-04 03_49_52", "rb") as f:
    lda_model = pkl.load(f)

with open("../models/corpus600002017-11-03 22_37_14", "rb") as f:
    corpus = pkl.load(f)

with open("../models/dic2017-11-03 22_37_15", "rb") as f:
    dic = pkl.load(f)

lda_model.print_topics(num_topics=100, num_words=10)

data = pyLDAvis.gensim.prepare(lda_model, corpus, dic)
