"""
Generate corpus from tokenized docs docs.pkl. Serialize it as acl_bow.mm
"""
import _pickle as pkl
from gensim.models import Phrases
from gensim.corpora import Dictionary
from tqdm import tqdm
import gensim
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = [logging.StreamHandler()]

v = 2
logging.info("Corpus Version " + str(v))
with open("docs" + str(v) + ".pkl", "rb") as f:
    docs = pkl.load(f)

bigram = Phrases(tqdm(docs), min_count=20)

for idx in tqdm(range(len(docs))):
    for token in bigram[docs[idx]]:
        if '_' in token:
            # Token is a bigram, add to document.
            docs[idx].append(token)

del bigram
dictionary = Dictionary(tqdm(docs))

max_freq = 0.4
min_wordcount = 5
max_number = 10000
logger.info("Filtering extremes in dictionary..")
dictionary.filter_extremes(no_below=min_wordcount, no_above=max_freq, keep_n=max_number)
_ = dictionary[0]  # This sort of "initializes" dictionary.id2token.
corpus = [dictionary.doc2bow(doc) for doc in docs]

print('Number of unique tokens: %d' % len(dictionary))
# Number of unique tokens: 60434
print('Number of documents: %d' % len(corpus))
# Number of documents: 23595

gensim.corpora.MmCorpus.serialize('acl_bow' + str(v) + '.mm', corpus, id2word=dictionary)
dictionary.save('dict' + str(v) + '.pkl')
