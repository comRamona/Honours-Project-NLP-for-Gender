# -*- coding: utf-8 -*-
"""Machine Learning Practical package."""

__authors__ = ['Ramona Comanescu']

DEFAULT_SEED = 123456  # Default random number generator seed if none provided.
from enum import Enum

class Gender(Enum):
    male = 0
    female = 1
    unknown = 2
