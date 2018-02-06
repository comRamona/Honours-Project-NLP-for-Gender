import os
import _pickle as pkl


class FileDir():

    def __init__(self):
        self.dir = os.path.join(os.environ["AAN_DIR"])
        self.models = os.path.join(self.dir, "save")
        if not os.path.exists(self.models):
            os.makedirs(self.models)
        self.plots = os.path.join(self.dir, "plots")
        if not os.path.exists(self.plots):
            os.makedirs(self.plots)
        self.papers = os.path.join(self.dir, "papers_text")
        if not os.path.exists(self.papers):
            os.makedirs(self.papers)

    def save_pickle(self, obj, name):
        name = os.path.join(self.models, name + ".pkl")
        with open(name, "wb") as f:
            pkl.dump(obj, f)

    def load_pickle(self, name):
        with open(os.path.join(self.models, name + ".pkl"), "rb") as file:
            dicty = pkl.load(file)
        return dicty

    def get_dir(self):
        return self.dir
