#!/usr/bin/env python3
"""
This script patches the adoc files given as arguments by fixing xref: links.

It rewrites include::modules/ statements by referencing the partials in the root module,
and rewrites relative xref: links to absolute ones from the module root, as antora
does not support relative links between pages.
"""

import os
import sys
import re


xref_re = re.compile(r"xref:([^[#]+\.adoc)")


def patch_file(filepath):
    with open(filepath, 'r') as f:
        contents = f.read()
    contents = contents.replace('include::modules/', 'include::ROOT:partial$')

    dirpath = os.path.dirname(filepath) + '/'
    pages_idx = dirpath.find('/ROOT/pages/')
    if pages_idx != -1:
        page_dir = dirpath[pages_idx + len('/ROOT/pages/'):]

        def to_abs_path(m):
            return "xref:" + os.path.normpath(page_dir + m.group(1))

        contents = xref_re.sub(to_abs_path, contents)

    with open(filepath, 'w') as f:
        f.write(contents)


for filepath in sys.argv[1:]:
    patch_file(filepath)
