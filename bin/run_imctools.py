#!/usr/bin/env python

import os
import sys
import argparse
import re

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
Epilog = """Example usage: python run_imctools.py <MCD/TXT/TIFF> <METADATA_FILE>"""

argParser = argparse.ArgumentParser(description=Description, epilog=Epilog)
argParser.add_argument('INPUT_FILE', help="Input files with extension '.mcd', '.txt', or '.tiff'.")
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

## OUTPUT FILE LINKING ROI IDS TO ROI LABELS (IMAGE DESCRIPTION)
roi_map = open(os.path.basename(args.INPUT_FILE)+'_ROI_map.csv', "w")

## USE DIFFERENT PARSERS CORRESPONDING TO THE INPUT FILE FORMAT
file_type = re.sub(".*\.([^.]+)$", '\\1', args.INPUT_FILE.lower())

## CONVERT INPUT_FILE TO TIFF AND WRITE RELEVANT TIFF IMAGES
if file_type == "mcd":
    parser = mcdparser.McdParser(args.INPUT_FILE)
    acids = parser.acquisition_ids
else:
    if file_type == "txt":
        parser = txtparser.TxtParser(args.INPUT_FILE)
    elif file_type == "tiff" or file_type == "tif":
        parser = omeparser.OmetiffParser(args.INPUT_FILE)
    else:
        print("{}: Invalid input file type - should be txt, tiff, or mcd!".format(file_type))
        sys.exit(1)

    # THERE IS ONLY ONE ACQUISITION - ROI FOLDER NAMED ACCORDING TO INPUT FILENAME
    acids = [ re.sub('.txt|.tiff', '', os.path.basename(parser.filename).lower().replace(" ", "_")) ]

for roi_number in acids:
    if file_type == "mcd":
        imc_ac = parser.get_imc_acquisition(roi_number)
        acmeta = parser.meta.get_object(meta.ACQUISITION, roi_number)
        roi_label = parser.get_acquisition_description(roi_number)
        roi_map.write("roi_%s,%s,%s,%s" % (roi_number, roi_label, acmeta.properties['StartTimeStamp'], acmeta.properties['EndTimeStamp']) + "\n")
    else:
        imc_ac = parser.get_imc_acquisition()

        # NO INFORMATION ON IMAGE ACQUISITION TIME FOR TXT AND TIFF FILE FORMATS
        roi_map.write("roi_%s,,," % (roi_number) + "\n")

    for i,j in enumerate(HEADER[1:]):
        ## WRITE TO APPROPRIATE DIRECTORY
        dirname = "roi_%s/%s" % (roi_number, j)
        if not os.path.exists(dirname):
            os.makedirs(dirname)

        # SELECT THE METALS FOR THE CORRESPNDING STACK (i) TO CREATE OME TIFF STACK
        label_indices = [ idx for idx in range(0, len(imc_ac.channel_labels)) if len([ entry for entry in metalDict if imc_ac.channel_labels[idx].upper().startswith(entry) and metalDict[entry][i]]) > 0 ]
        metal_stack = [ imc_ac.channel_metals[idx] for idx in label_indices ]

        if len(metal_stack) > 0:
            img = imc_ac.get_image_writer(filename=os.path.join("roi_%s" % (roi_number), "%s.ome.tiff" % j), metals=metal_stack)
            img.save_image(mode='ome', compression=0, dtype=None, bigtiff=True)
        else:
            print("None of the metals exists in metasheet file for {}".format(j))
            sys.exit(1)

        for l, m in zip(imc_ac.channel_labels, imc_ac.channel_metals):
            filename = "%s.tiff" % (l)

            # MATCH METAL LABEL TO METADATA METAL COLUMN
            metal_label = l.split('_')[0].upper()
            metal = [ entry for entry in metalDict if metal_label.upper().startswith(entry) and metalDict[entry][i] ]
            if len(metal) == 1:
                if metalDict[metal[0]][i]:
                    img = imc_ac.get_image_writer(filename=os.path.join(dirname,filename), metals=[m])
                    img.save_image(mode='ome', compression=0, dtype=None, bigtiff=False)
            elif len(metal) > 1:
                print("{} metal has multiple matches found".format(metal_label))
            elif len([ entry for entry in metalDict if metal_label.upper().startswith(entry)]) == 0:
                print("{} metal does not exist in metasheet file".format(metal_label))
roi_map.close()
