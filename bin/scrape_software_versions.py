#!/usr/bin/env python
from __future__ import print_function
from collections import OrderedDict
import re

regexes = {
    'nf-core/imcyto': ['pipeline_version.txt', r"(\S+)"],
    'Nextflow': ['nextflow_version.txt', r"(\S+)"],
    'imctools': ['imctools_version.txt', r"Version: (\S+)"],
    'CellProfiler': ['cellprofiler_version.txt', r"(\S+)"],
    'Ilastik' : ['ilastik_version.txt', r"(\S+)"]
}

results = OrderedDict()
results['nf-core/imcyto'] = '<span style="color:#999999;\">N/A</span>'
results['Nextflow'] = '<span style="color:#999999;\">N/A</span>'
results['imctools'] = '<span style="color:#999999;\">N/A</span>'
results['CellProfiler'] = '<span style="color:#999999;\">N/A</span>'
results['Ilastik'] = '<span style="color:#999999;\">N/A</span>'

# Search each file using its regex
for k, v in regexes.items():
    try:
        with open(v[0]) as x:
            versions = x.read()
            match = re.search(v[1], versions)
            if match:
                results[k] = "v{}".format(match.group(1))
    except IOError:
        results[k] = False

# Remove software set to false in results
for k in list(results):
    if not results[k]:
        del(results[k])

# Dump to YAML
print ('''
id: 'software_versions'
section_name: 'nf-core/imcyto Software Versions'
section_href: 'https://github.com/nf-core/imcyto'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
''')
for k,v in results.items():
    print("        <dt>{}</dt><dd><samp>{}</samp></dd>".format(k,v))
print ("    </dl>")

# Write out regexes as csv file:
with open('software_versions.csv', 'w') as f:
    for k,v in results.items():
        f.write("{}\t{}\n".format(k,v))
