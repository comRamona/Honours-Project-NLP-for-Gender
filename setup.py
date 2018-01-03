""" Setup script for mlp package. """

from setuptools import setup
from setuptools.command.develop import develop
from setuptools.command.install import install


def friendly(command_subclass):
    """A decorator for classes subclassing one of the setuptools commands.

    It modifies the run() method so that it prints a friendly greeting.
    """
    orig_run = command_subclass.run

    def modified_run(self):
        print("Hello, developer, how are you? :)")
        orig_run(self)

    command_subclass.run = modified_run
    return command_subclass


@friendly
class CustomDevelopCommand(develop):
    pass


@friendly
class CustomInstallCommand(install):
    pass


setup(
    name="honours",
    author="Ramona Comanescu",
    description=("Honours Project code for University of Edinburgh "
                 "School of Informatics"),
    url="https://github.com/comRamona/Honours-LDA",
    packages=['metadata', '_name_classification', '_data_cleaning', '_topic_modeling']
)
