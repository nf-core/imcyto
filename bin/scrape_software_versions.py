#!/usr/bin/env python
from __future__ import print_function
from collections import OrderedDict
import re

# TODO nf-core: Add additional regexes for new tools in process get_software_versions
regexes = {
    'nf-core/imcyto': ['v_pipeline.txt', r"(\S+)"],
    'Nextflow': ['v_nextflow.txt', r"(\S+)"],
    'CellProfiler': ['v_cellprofiler.txt', r"(\S+)"],
    'Ilastik': ['v_ilastik.txt', r"(\S+)"]
    #'imctools': ['v_imctools.txt', r"(\S+)"],
}

results = OrderedDict()
results['nf-core/imcyto'] = 'NA'
results['Nextflow'] = 'NA'
results['CellProfiler'] = 'NA'
results['Ilastik'] = 'NA'
#results['imctools'] = 'NA'

# Search each file using its regex
for k, v in regexes.items():
    with open(v[0]) as x:
        versions = x.read()
        match = re.search(v[1], versions)
        if match:
            results[k] = "v{}".format(match.group(1))

# Dump to TSV
for k,v in results.items():
    print("{}\t{}".format(k,v))
