#!/usr/bin/env python
"""Add all of the modules in the current directory to __all__"""
import os
import sys

__all__ = []

# import api classes and ApiClient class
for module in os.listdir(os.path.dirname(__file__)):
    if module != '__init__.py' and module[-3:].endswith('.py'):
        if module[:-3] == 'swagger':
            __all__.append('ApiClient')
            _temp = __import__(module[:-3],
                               globals(),
                               locals(),
                               ['ApiClient'], -1)
            globals().update({'ApiClient': getattr(_temp, 'ApiClient')})
        else:
            __all__.append(module[:-3])
            _temp = __import__(module[:-3],
                               globals(),
                               locals(),
                               [module[:-3]], -1)
            globals().update({module[:-3]: getattr(_temp, module[:-3])})


# import model classes
for module in os.listdir(os.path.join(os.path.dirname(__file__), 'models')):
    if module != '__init__.py' and module[-3:].endswith('.py'):
        __all__.append(module[:-3])
        _temp = __import__("models.{}".format(module[:-3]),
                           globals(),
                           locals(),
                           [module[:-3]], -1)
        globals().update({module[:-3]: getattr(_temp, module[:-3])})
