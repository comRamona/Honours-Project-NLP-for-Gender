""" Setup script for mlp package. """

from setuptools import setup

setup(
    name = "honours",
    author = "Ramona Comanescu",
    description = ("Honours Project code for University of Edinburgh "
                   "School of Informatics"),
    url = "https://github.com/comRamona/Honours-LDA",
    packages=['honours', '_name_classification', '_data_cleaning', '_topic_modeling']
)

