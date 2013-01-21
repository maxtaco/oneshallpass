
import sys
import re
import os
import os.path

def process_handle (inh, outh):
    rxx = re.compile(r'^(.*)\{%\s?include\s+(.*?)%\}(.*)$');
    for l in inh.readlines():
        m = rxx.match(l)
        if m:
            pre = m.group(1)
            fn = m.group(2).strip()
            post = m.group(3)
            sys.stdout.write(pre)
            fn = os.path.join ("out", fn)
            nh = open (fn, "r")
            process_handle (nh)
            outh.write(post)
        else:
            outh.write(l)

process_handle (sys.stdin, sys.stdout)
