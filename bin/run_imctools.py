#!/usr/bin/env python

import os
import sys
import argparse

import imctools.io.mcdparser as mcdparser
import imctools.io.txtparser as txtparser
import imctools.io.ometiffparser as omeparser
import imctools.io.mcdxmlparser as meta

############################################
############################################
## PARSE ARGUMENTS
############################################
############################################

Description = 'Split nf-core/imcyto input data by full/ilastik stack.'
Epilog = """Example usage: python run_imctools.py <MCD_FILE> <METADATA_FILE>"""

argParser = argparse.ArgumentParser(description=Description, epilog=Epilog)
argParser.add_argument('MCD_FILE', help="Input files with extension '.mcd'.")
argParser.add_argument('METADATA_FILE', help="Metadata file containing 3 columns i.e. metal,full_stack,ilastik_stack. See pipeline usage docs for file format information.")
args = argParser.parse_args()

############################################
############################################
## PARSE & VALIDATE INPUTS
############################################
############################################

## READ AND VALIDATE METADATA FILE
ERROR_STR = 'ERROR: Please check metadata file'
HEADER = ['metal', 'full_stack', 'ilastik_stack']

fin = open(args.METADATA_FILE,'r')
header = fin.readline().strip().split(',')
if header != HEADER:
	print("{} header: {} != {}".format(ERROR_STR,','.join(header),','.join(HEADER)))
	sys.exit(1)

metalDict = {}
for line in fin.readlines():
	lspl = line.strip().split(',')
	metal,fstack,istack = lspl

	## CHECK THREE COLUMNS IN LINE
	if len(lspl) != len(HEADER):
		print("{}: Invalid number of columns - should be 3!\nLine: '{}'".format(ERROR_STR,line.strip()))
		sys.exit(1)

	## CHECK VALID INCLUDE/EXCLUDE CODES
	if fstack not in ['0','1'] or istack not in ['0','1']:
		print("{}: Invalid column code - should be 0 or 1!\nLine: '{}'".format(ERROR_STR,line.strip()))
		sys.exit(1)

	## CREATE DICTIONARY
	metal = metal.upper()
	if metal not in metalDict:
		metalDict[metal] = [bool(int(x)) for x in [fstack,istack]]
fin.close()

##	OUTPUT FILE LINKING ROI IDS TO ROI LABELS (IMAGE DESCRIPTION)
roi_map = open(os.path.basename(args.MCD_FILE)+'_ROI_map.csv', "w")

## COMVERT MCD TO TIFF AND WRITE RELEVANT TIFF IMAGES
mcd = mcdparser.McdParser(args.MCD_FILE)
for acid in mcd.acquisition_ids:
	imc_ac = mcd.get_imc_acquisition(acid)
	roi_label = mcd.get_acquisition_description(acid)
	roi_map.write("roi_%s,%s" % (acid, roi_label) + "\n")
	for l, m in zip(imc_ac.channel_labels, imc_ac.channel_metals):
		filename = "%s.tiff" % (l)

		## WRITE TO APPROPRIATE DIRECTORY
		metal = l.split('_')[0].upper()
		if metal in metalDict:
			for i,j in enumerate(HEADER[1:]):
				if metalDict[metal][i]:
					dirname = "roi_%s/%s" % (acid,j)
					if not os.path.exists(dirname):
						os.makedirs(dirname)
					img = imc_ac.get_image_writer(filename=os.path.join(dirname,filename), metals=[m])
					img.save_image(mode='ome', compression=0, dtype=None, bigtiff=False)
		else:
			print("{} metal does not exist in metasheet file".format(metal))
roi_map.close()
