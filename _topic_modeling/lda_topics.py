
# coding: utf-8

# In[1]:
# 
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
# increase the d 

# In[113]:


from os import listdir
from os.path import isfile, join
from os import environ
from nltk.tokenize import TreebankWordTokenizer, word_tokenize
import re


# In[49]:




from time import time

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation

    
train_files = [join(environ["AAN_DIR"],"papers_text/{0}".format(fn)) for fn in 
               listdir(join(environ["AAN_DIR"],"papers_text/")) if "txt" in fn]

def dehyphenate(s):
    return s.replace('-\n','').lower()


# In[155]:


train_files


# In[161]:


def print_top_words(model, feature_names, n_top_words):
    for topic_idx, topic in enumerate(model.components_):
        message = "Topic #%d: " % topic_idx
        message += " ".join([feature_names[i]
                             for i in topic.argsort()[:-n_top_words - 1:-1]])[:300]
        print(message)
    print()


# In[178]:


# Use tf (raw term count) features for LDA.
print("Extracting tf features for LDA...")
tf_vectorizer = CountVectorizer(max_df=0.95, 
                                input='filename',
                                min_df=5,
                                #max_features=n_features,
                                stop_words='english',
                                token_pattern=r"(?u)\b[a-zA-Z][a-zA-Z]+\b",
                                preprocessor = dehyphenate
                                #tokenizer=TreebankWordTokenizer().tokenize
                                )
t0 = time()
tf = tf_vectorizer.fit_transform(train_files)
print("done in %0.3fs." % (time() - t0))
print()


n_components = 100
n_top_words = 20


# In[ ]:


print("Fitting LDA models with tf features")

lda = LatentDirichletAllocation(n_components=n_components, max_iter=5,
                                learning_method='online',
                                random_state=0)
t0 = time()
lda.fit(tf)
print("done in %0.3fs." % (time() - t0))


# In[173]:


print("\nTopics in LDA model:")
tf_feature_names = tf_vectorizer.get_feature_names()
print_top_words(lda, tf_feature_names, n_top_words)

import pickle
pickle.dump(lda,open('lda_save.p','wb'))





