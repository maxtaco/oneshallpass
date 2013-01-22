import sys
import re
import os
import os.path
import getopt

minify = False
opts, args = getopt.getopt(sys.argv[1:], 'm')
for o,a in opts:
    if o == '-m':
        print "minify!"
        minify = True


def process_handle (inh, outh):
    rxx = re.compile(r'^(.*)\{%\s?include\s+(.*?)%\}(.*)$');
    for l in inh.readlines():
        m = rxx.match(l)
        if m:
            pre = m.group(1)
            fn = m.group(2).strip()
            post = m.group(3)
            sys.stdout.write(pre)
            jsdir = "js-min" if minify else "js" 
            fn = os.path.join ("build", jsdir, fn)
            nh = open (fn, "r")
            process_handle (nh, outh)
            outh.write(post)
        else:
            outh.write(l)

process_handle (sys.stdin, sys.stdout)
