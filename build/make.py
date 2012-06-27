
import sys
import re

def process_handle (h):
    rxx = re.compile(r'^(.*)\{%\s?include\s+(.*?)%\}(.*)$');
    for l in h.readlines():
        m = rxx.match(l)
        if m:
            pre = m.group(1)
            file = m.group(2).strip()
            post = m.group(3)
            sys.stdout.write(pre)
            nh = open (file, "r")
            process_handle (nh)
            sys.stdout.write(post)
        else:
            sys.stdout.write(l)

process_handle (sys.stdin)
