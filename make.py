
import sys
import re

rxx = re.compile("%\{include\\s+(.*?)\}")
for l in sys.stdin.readlines():
    m = rxx.match (l)
    if m:
        file = m.group(1)
        print m
