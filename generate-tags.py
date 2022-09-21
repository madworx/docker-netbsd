#!/usr/bin/python3

import re
import sys

sys.argv.pop(0)
build_version = sys.argv.pop(0)
available_versions = sys.argv

p = re.split(r'[._]', build_version)
if len(p) > 2: # RC is to be only explicitly tagged.
    print(f"{p[0]}.{p[1]}{p[2].lower()}")
else:
    out = f"{p[0]}.{p[1]}"
    major_highest = sorted([x for x in [re.split(r'[._]', x) for x in available_versions] if len(x) < 3], reverse=True)[0]
    minor_highest = sorted([x for x in [re.split(r'[._]', x) for x in available_versions] if len(x) < 3 and x[0] == p[0]], reverse=True)[0]
    if p == minor_highest:
        out = out + f" {p[0]}"
    if p == major_highest:
        out = out + " latest"
    print(out)
