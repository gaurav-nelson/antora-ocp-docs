#!/usr/bin/env python3
"""
This scripts reads the `_topic_map.yml` file of OpenShift docs
(https://github.com/openshift/openshift-docs/blob/rhacs-docs/_topic_map.yml), and translates it
to Antora's format, creating nav.adoc files in the respective module directories, along with an
antora.yml file in the docs root directory.
"""

import yaml
import sys

records = yaml.safe_load_all(sys.stdin.read())

root_config = {
    'name': 'rhacs',
    'title': 'Red Hat Advanced Cluster Security for Kubernetes',
    'version': 'latest',
    'start_page': 'ROOT:welcome/index.adoc',
    'nav': ['modules/ROOT/nav.adoc']
}


def print_topic_nav(topics, f, prefix="", dir_prefix=""):
    for t in topics:
        if 'Topics' in t:
            f.write(f"{prefix}* {t['Name']}\n")
            next_dir_prefix = dir_prefix
            if 'Dir' in t:
                next_dir_prefix = dir_prefix + t['Dir'] + "/"
            print_topic_nav(t['Topics'], f=f, prefix=prefix + "*", dir_prefix=next_dir_prefix)
        else:
            f.write(f"{prefix}* xref:{dir_prefix}{t['File']}.adoc[{t['Name']}]\n")


with open('docs/modules/ROOT/nav.adoc', 'w') as f:
    print_topic_nav(records, f)

# Write the antora.yml config file.
with open('docs/antora.yml', 'w') as f:
    yaml.safe_dump(root_config, stream=f)
