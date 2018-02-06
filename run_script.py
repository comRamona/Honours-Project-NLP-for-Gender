import sys
import importlib

f = sys.argv[1]
i = sys.argv[2]
importlib.import_module(f + "." + i)

