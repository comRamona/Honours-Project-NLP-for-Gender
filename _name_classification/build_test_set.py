
import os
import re
from metadata import Gender
import _pickle as pkl
import logging
import random
from _name_classification.classifyname import NC

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
random.seed(1)

class TestSet():

    def __init__(self):
        labeled_set = []
        webnames = set()
        total = []
        with open(os.path.join(os.environ['AAN_DIR'], "webnames.txt"), "r") as file:
            names = file.read().split("\n")
            for name in names:
                webnames.add(name)
        with open(os.path.join(os.environ['AAN_DIR'], "acl-female.txt"), "r") as file:
            females = file.read().split("\n")
            for f in females[:-1]:
                total.append(f)
                if f not in webnames:
                    labeled_set.append((f, Gender.female))
        with open(os.path.join(os.environ['AAN_DIR'], "acl-male.txt"), "r") as file:
            males = file.read().split("\n")
            for m in males[:-1]:
                total.append(m)
                if m not in webnames:
                    labeled_set.append((m, Gender.male))

        n = len(labeled_set)
        sample_size = int(round(n*0.1))
        sample_index = sorted(random.sample(range(n), sample_size))
        self.sample_corpus = [labeled_set[j] for j in sample_index]

        logger.info("Total size of test set: {0} \n Sample size: {1} \n Example: \n"
                       "{2}, {3} ".format(n, len(self.sample_corpus), self.sample_corpus[0],
                       self.sample_corpus[random.randint(0, len(self.sample_corpus))]))

        logger.info("Females: {0}".format(len(list(filter(lambda x: x[1] == Gender.female, self.sample_corpus)))))
        logger.info("Males: {0}".format(len(list(filter(lambda x: x[1] == Gender.male, self.sample_corpus)))))
        self.nc = NC()

    def test_classifier(self):
        correct = 0
        fem_as_male = 0
        male_as_fem = 0
        unk = 0
        for name in self.sample_corpus:
            gender = self.nc.classify_name(name[0], False)
            if len(gender) > 1:
                rep = gender[0]
            else:
                rep = gender
            if rep != name[1] and rep != Gender.unknown:
                logger.info("Name: {2}, True: {0}, Assigned: {1}".format(name[1],gender, name[0]))
            gender = rep
            if gender == Gender.unknown:
                unk += 1
            elif gender == Gender.female:
                if name[1] == Gender.female:
                    correct += 1
                else:
                    male_as_fem += 1
            else:
                if name[1] == Gender.male:
                    correct += 1
                else:
                    fem_as_male += 1
        logger.info("Correct: {0}, Fem as male: {1}, Male as female: {2}, Unknown{3}".format(correct, fem_as_male, male_as_fem, unk))

t = TestSet()
t.test_classifier()
