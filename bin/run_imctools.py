#!/usr/bin/env python

import os
import sys
import imctools.io.mcdparser as mcdparser
import imctools.io.txtparser as txtparser
import imctools.io.ometiffparser as omeparser
import imctools.io.mcdxmlparser as meta

fn_mcd = sys.argv[1]
metadata = sys.argv[2]

## READ AND VALIDATE METADATA FILE
ERROR_STR = 'ERROR: Please check metadata file'
HEADER = ['metal', 'full_stack', 'ilastik_stack']

fin = open(metadata,'r')
header = fin.readline().strip().split(',')
if header != HEADER:
	print "{} header: {} != {}".format(ERROR_STR,','.join(header),','.join(HEADER))
 	sys.exit(1)

metalDict = {}
for line in fin.readlines():
	lspl = line.strip().split(',')

	## CHECK THREE COLUMNS IN LINE
	if len(lspl) != len(HEADER):
		print "{}: Invalid number of columns - should be 3!\nLine: '{}'".format(ERROR_STR,line.strip())
		sys.exit(1)

	## CHECK VALID INCLUDE/EXCLUDE CODES
	if lspl[1] not in ['0','1'] or lspl[2] not in ['0','1']:
		print "{}: Invalid column code - should be 0 or 1!\nLine: '{}'".format(ERROR_STR,line.strip())
		sys.exit(1)

	metal = lspl[0].upper()
	if not metalDict.has_key(metal):
		metalDict[metal] = [bool(int(x)) for x in lspl[1:]]
fin.close()

## COMVERT MCD TO TIFF AND WRITE RELEVANT TIFF IMAGES
mcd = mcdparser.McdParser(fn_mcd)
for acid in mcd.acquisition_ids:
	imc_ac = mcd.get_imc_acquisition(acid)
	for l, m in zip(imc_ac.channel_labels, imc_ac.channel_metals):
		filename = "%s.tiff" % (l)

		## WRITE TO APPROPRIATE DIRECTORY
		metal = l.split('_')[0].upper()
		if metal in metalDict.keys():
			for i,j in enumerate(HEADER[1:]):
				if metalDict[metal][i]:
					dirname = "roi_%s/%s" % (acid,j)
					if not os.path.exists(dirname):
						os.makedirs(dirname)
					img = imc_ac.get_image_writer(filename=os.path.join(dirname,filename), metals=[m])
					img.save_image(mode='ome', compression=0, dtype=None, bigtiff=False)
