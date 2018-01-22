import re
from metadata.metadata import ACL_metadata
import logging
import _pickle as pkl
from tqdm import tqdm
import numpy as np
import spacy

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = [logging.StreamHandler()]

np.random.seed(18101995)
nlp = spacy.load('en')

v = 8
logging.info("Tokenize Version " + str(v))
# Remove hyphens from words, to solve cases like he-llo
def dehyphenate(s):
    return s.replace('-\n', '')


acl = ACL_metadata()

# Get all document texts and their corresponding IDs.
docs = []
doc_ids = []
for file in tqdm(acl.modeling_files):
    doc_ids.append(acl.get_id(file))
    with open(file, errors='ignore', encoding='utf-8') as fid:
        txt = fid.read()

        # Replace any whitespace (newline, tabs, etc.) by a single space.
        txt = re.sub('\s+', ' ', txt)
        txt = dehyphenate(txt)
        
        # keep only text between abstract and references, if possible
        first = 0
        for first_word in ["Abstract", "Abst ract", "Introduction"]:
            first = txt.find(first_word)
            if first != -1:
                first = first - len(first_word)
                break
        if first == -1:
            logger.info("Couldn't find abstract for document " + str(file))
            first = 0

        last = len(txt)
        for end_word in ["References", "Bibliography", "Acknowledgments", "Acknowledgment"]:
            last = txt.rfind(end_word)
            if last != -1:
                last = last - len(end_word)
                break
        if last == -1:
            logger.info("Couldn't find references for document " + str(file))
            last = len(txt)
        txt = txt[first: last]
        txt = txt.lower()
        docs.append(txt)

with open("doc" +str(v) + "_ids.pkl", "wb") as f:
    pkl.dump(doc_ids, f)
del doc_ids
del acl 
del txt
logger.info("Starting Tokenization..")

processed_docs = []
for doc in nlp.pipe(tqdm(docs), n_threads=4, batch_size=100):
    # Process document using Spacy NLP pipeline.

    ents = doc.ents  # Named entities.

    # Keep only words (no numbers, no punctuation).
    # Lemmatize tokens, remove punctuation and remove stopwords.
    doc = [token.lemma_ for token in doc if token.is_alpha and not token.is_stop and len(token) >= 3]

    # Remove common words from a stopword list.
    # doc = [token for token in doc if token not in STOPWORDS]

    # Add named entities, but only if they are a compound of more than word.
    doc.extend([str(entity) for entity in ents if len(entity) > 1])

    processed_docs.append(doc)

del docs 
logger.info("Saving tokenized documents")
with open("docs" + str(v) + ".pkl", "wb") as f:
    pkl.dump(processed_docs, f)

logger.info("Sanity test:\n") 
print(processed_docs[0])
del processed_docs

