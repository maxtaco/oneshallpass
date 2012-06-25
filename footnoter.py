
import re
import sys

class CitationException(Exception):
    pass


class Ref:
    def __init__ (self, label):
        self._label = label

    def resolve_to (self, c):
        self._citation = c

    def output (self, h):
        h.write("[%d](#citations)" % self._citaiton.get_number())

class Text:
    def __init__ (self, txt):
        self._txt = txt

    def output(self, h):
        h.write(self._txt)

class Citation:
    def __init__ (self, label, body):
        self._label = label
        self._body = body
        self._number = None

    def label(self):
        return _label

    def get_number(self):
        return self._number

    def set_number(self, n):
        if self._number:
            return False
        else:
            self._number = n
            return True

    def output(self, h):
        h.write("\\[%d\\]: %s\n\n", self._number, self._body)


class Table:
    def __init__ (self):
        self._tab = {}
        self._counter = 1

    def insert (self, c):
        if self._tab.get(c.label()):
            raise CitationException, "citation double-defined: %s" % c.label()
        else:
            self._tab[c.label()] = c

    def lookup (self, r):
        c = self._tab.get(r.label())
        if not c:
            raise CitationException, "undefined citation: %s" % r.label()
        return c

    def resolve (self, r):
        c = self.lookup(r)
        r.resolve_to(c)
        if c.set_number(self._counter):
            self._counter++

def process (inh, outh):
    rxx =  re.compile('\{#(\!(.*?):)?(.*?)#\}')
    txt = inh.read()
    raw_tokens = rxx.split (txt)
    nodes = []
    refs = []
    tab = Table()

    while (l = len(raw_tokens)):

        n = 0
        if l == 1:
            n = 1
            nodes.append (Text(raw_tokens[0]))
        else if l < 4:
            raise CitationException, "weird number of tokens"
        else:
            nodes.append (Text(raw_tokens[0]))
            if not raw_tokens[1]:
                r = Ref(raw_tokens[3])
                refs.append (r)
            else:
                cite = Citation(raw_tokens[2], raw_tokens[3])
                table.insert (cite)
                nodes.append(cite)
            n = 4

        # slice off the consumed tokens
        raw_tokens = raw_tokens[n:]

    for r in refs:
        tab.resolve(r)

    for n in nodes:
        n.output(outh)


process (sys.stdin, sys.stdout)
