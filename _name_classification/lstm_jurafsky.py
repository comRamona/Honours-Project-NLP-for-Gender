from __future__ import print_function
from keras.callbacks import LambdaCallback
from keras.models import Sequential
from keras.layers import Dense, Activation
from keras.layers import LSTM
from keras.optimizers import RMSprop
from keras.utils.data_utils import get_file
import numpy as np
import random
import sys
import io
from os import listdir
from os.path import isfile, join
from os import environ
from keras.models import model_from_json


labeled_set = []
webnames = set()
female_names = []
male_names = []
with open(join(environ['AAN_DIR'], "webnames.txt"), "r") as file:
    names = file.read().split("\n")
    for name in names:
        webnames.add(name)
with open(join(environ['AAN_DIR'], "acl-female.txt"), "r") as file:
    females = file.read().split("\n")
    for f in females[:-1]:
        if f not in webnames:
            f = f.lower()
            female_names.append(f)
           
with open(join(environ['AAN_DIR'], "acl-male.txt"), "r") as file:
    males = file.read().split("\n")
    for m in males[:-1]:
        if m not in webnames:
            m = m.lower()
            male_names.append(m)

males_size = int(round(len(female_names)))
males_index = sorted(random.sample(range(len(male_names)), males_size))
males_sample = [male_names[j] for j in males_index]
inputs = female_names + males_sample
labels = [1] * len(female_names) + [0] * len(males_sample)
assert  (len(labels) == len(inputs)), "labels and inputs have different sizes"

shuffled_ = list(range(len(labels)))
random.shuffle(shuffled_)
labels = [labels[i] for i in shuffled_]
inputs = [inputs[i] for i in shuffled_]

train_size = int(round(len(inputs) * 0.8))
train_index = sorted(random.sample(range(len(inputs)), train_size))
test_index = sorted(set(range(len(inputs))) - set(train_index))
x_train = [inputs[i] for i in train_index]
x_test = [inputs[j] for j in test_index]
y_train = [labels[i] for i in train_index]
y_test = [labels[j] for j in test_index]


chars = sorted(list(set(",".join(x_train))))
print('total chars:', len(chars))
char_indices = dict((c, i) for i, c in enumerate(chars))
oov = len(chars)
indices_char = dict((i, c) for i, c in enumerate(chars))

# cut the text in semi-redundant sequences of maxlen characters
maxlen = 40
step = 3
sentences = []
next_chars = []
# for i in range(0, len(text) - maxlen, step):
#     sentences.append(text[i: i + maxlen])
#     next_chars.append(text[i + maxlen])
# print('nb sequences:', len(sentences))

print('Vectorization...')
X_train = np.zeros((len(train_index), maxlen, len(chars)), dtype=np.bool)
y_train = np.array(y_train)
for i, name in enumerate(x_train):
    for t, char in enumerate(name):
        X_train[i, t, char_indices[char]] = 1

X_test = np.zeros((len(test_index), maxlen, len(chars)), dtype=np.bool)
y_test = np.array(y_test)
for i, name in enumerate(x_test):
    for t, char in enumerate(name):
        index = char_indices.get(char, oov)
        if index != oov:
            X_test[i, t, index] = 1


# build the model: a single LSTM
print('Build model...')
model = Sequential()
model.add(LSTM(64, input_shape=(maxlen, len(chars))))
model.add(Dense(len(chars)))
model.add(Dense(1, activation='sigmoid'))

optimizer = RMSprop(lr=0.01)

# try using different optimizers and different optimizer configs
model.compile(loss='binary_crossentropy', optimizer=optimizer,metrics=['binary_accuracy'])
batch_size = 32

print('Train...')
model.fit(X_train, y_train,
          batch_size=batch_size,
          epochs=20,
          validation_data=[X_test, y_test])

predictions = model.predict([X_test], verbose=0)
test_acc = np.mean((predictions > 0.5) == y_test.reshape(-1, 1))

# serialize model to JSON
model_json = model.to_json()
with open("model_jurafsky.json", "w") as json_file:
    json_file.write(model_json)
# serialize weights to HDF5
model.save_weights("model.h5")
print("Saved model to disk")
 
# later...
 
# # load json and create model
# json_file = open('model.json', 'r')
# loaded_model_json = json_file.read()
# json_file.close()
# loaded_model = model_from_json(loaded_model_json)
# # load weights into new model
# loaded_model.load_weights("model.h5")
# print("Loaded model from disk")

# # evaluate loaded model on test data
#loaded_model.compile(loss='binary_crossentropy', optimizer='rmsprop', metrics=['accuracy'])
#score = loaded_model.evaluate(X, Y, verbose=0)

def predict_gender(name, maxlen=40, chars=31):
    X_test = np.zeros((1, maxlen, chars), dtype=np.bool)
    for t, char in enumerate(name):
        index = char_indices.get(char, oov)
        if index != oov:
            X_test[0, t, index] = 1
    predictions = model.predict(X_test)[0]
    print(predictions)
    p = predictions > 0.5
    if p:
        return "Female"
    else:
        return "Male"