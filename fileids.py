import _pickle as pkl

from indexes import ACL_metadata
from functools import reduce
import _pickle as pkl
import os
from os.path import join
from os import environ


class FileIds():

    def __init__(self):
        acl = ACL_metadata()


        ids = set(acl.df.index)
        tf  = set()
        for f in acl.train_files:
            i = acl.get_id(f)
            tf.add(i)

        interesting = tf.intersection(ids)

        self.unique_df = acl.df.loc[interesting]