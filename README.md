# ![nfcore/imcyto](docs/images/nfcore-imcyto_logo.png)

[![Build Status](https://travis-ci.com/nf-core/imcyto.svg?branch=master)](https://travis-ci.com/nf-core/imcyto)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/imcyto.svg)](https://hub.docker.com/r/nfcore/imcyto)

## Introduction

**nfcore/imcyto** is a bioinformatics analysis pipeline used for Image Mass Cytometry analysis.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Pipeline summary

1. Convert mcd file into individual tiffs ([`imctools`](https://github.com/BodenmillerGroup/imctools))
2. Remove outliers and apply median filter to tiff files. Save as image sequence ([`Fiji`](https://fiji.sc/))
3. Find CD44, MHCcII, DNA tiffs and merge. Save as tiff ([`Fiji`](https://fiji.sc/))
4. Use merged tiff to classify pixels as membrane, nuclei, background. Save probabilities as tif sequence ([`Ilastik`](https://www.ilastik.org/))
5. Use probability tifs and filtered tiffs for single cell segmentation and create cell mask. Save as tiff. ([`CellProfiler`](https://cellprofiler.org/))
6. Overlay cell mask onto tiff images to extract single cell information and save as csv file ([`histoCAT`](http://www.bodenmillerlab.com/research-2/histocat/))

## Documentation

The nf-core/imcyto pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](docs/installation.md)
2. Pipeline configuration
    * [Local installation](docs/configuration/local.md)
    * [Adding your own system](docs/configuration/adding_your_own.md)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)

## Credits
The pipeline was originally written by the [The Bioinformatics & Biostatistics Group](https://www.crick.ac.uk/research/science-technology-platforms/bioinformatics-and-biostatistics/) for use at [The Francis Crick Institute](https://www.crick.ac.uk/), London.

The pipeline was developed by [Harshil Patel](mailto:harshil.patel@crick.ac.uk) and [Nourdine Bah](mailto:nourdine.bah@crick.ac.uk) in collaboration with [Karishma Valand](mailto:karishma.valand@crick.ac.uk), [Febe van Maldegem](mailto:febe.vanmaldegem@crick.ac.uk) and [Emma Colliver](mailto:emma.colliver@crick.ac.uk).

Many thanks to others who contributed as a result of the Crick Data Challenge (Jan 2019) - [Gavin Kelly](mailto:gavin.kelly@crick.ac.uk), [Becky Saunders](mailto:becky.saunders@crick.ac.uk), [Katey Enfield](mailto:katey.enfield@crick.ac.uk), [Alix Lemarois](mailto:alix.lemarois@crick.ac.uk), [Nuria Folguera Blasco](mailto:nuria.folguerablasco@crick.ac.uk), [Andre Altmann](mailto:a.altmann@ucl.ac.uk).

It would not have been possible to develop this pipeline without the guidelines, scripts and plugins provided by the [Bodenmiller Lab](http://www.bodenmillerlab.com/). Thank you too!
