# -*- encoding: UTF-8 -*-

import unicodedata
from unicodedata import normalize, category
import html

def _folditems():
    _folding_table = {
        # general non-decomposing characters
        # FIXME: This is not complete
        u"ł" : u"l",
        u"œ" : u"oe",
        u"ð" : u"d",
        u"þ" : u"th",
      
    }

    for c, rep in iter(_folding_table.items()):
        yield (ord(c.upper()), rep.title())
        yield (ord(c), rep)

folding_table = dict(_folditems())

def clean(ustr):
    u"""Fold @ustr

    Return a unicode str where composed characters are replaced by
    their base, and extended latin characters are replaced by
    similar basic latin characters.

    >>> tofolded(u"Wyłącz")
    u'Wylacz'
    >>> tofolded(u"naïveté")
    u'naivete'

    Characters from other scripts are not transliterated.

    >>> tofolded(u"Ἑλλάς") == u'Ελλας'
    True

    (These doctests pass, but should they fail, they fail hard)
    """
    ustr = html.unescape(ustr)
    ustr = ustr.replace("?","")
    srcstr = normalize("NFKD", ustr.translate(folding_table))
    return u"".join(c for c in srcstr if category(c) != 'Mn')
