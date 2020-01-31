# ![nfcore/imcyto](docs/images/nf-core-imcyto_logo.png)

[![GitHub Actions CI Status](https://github.com/nf-core/imcyto/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/imcyto/actions)
[![GitHub Actions Linting Status](https://github.com/nf-core/imcyto/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/imcyto/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

## Introduction

**nfcore/imcyto** is a bioinformatics analysis pipeline used for image segmentation and extraction of single cell expression data. This pipeline was generated for Imaging Mass Cytometry data, however, it is flexible enough to be applicable to other types of imaging data (e.g. immunofluorescence/immunohistochemistry data).

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Pipeline summary

<!-- TODO nf-core: I think the schematic should also be added here as it nicely illustrates what this pipeline is for. -->

1. Split image acquisition output files (`mcd`, `ome.tiff` or `txt`) by ROI and convert to individual `tiff` files for channels with names matching those defined in user-provided `metadata.csv` file. Full and ilastik stacks will be generated separately for all channels being analysed in single cell expression analysis, and for channels being used to generate the cell mask, respectively ([imctools](https://github.com/BodenmillerGroup/imctools)).

2. Apply pre-processing filters to full stack `tiff` files ([CellProfiler](https://cellprofiler.org/)).

3. Use selected `tiff` files in ilastik stack to generate a composite RGB image representative of the plasma membranes and nuclei of all cells ([CellProfiler](https://cellprofiler.org/)).

4. Use composite cell map to apply pixel classification for membranes, nuclei or background, and save probabilities map as `tiff` ([Ilastik](https://www.ilastik.org/)). If CellProfiler modules alone are deemed sufficient to achieve a reliable segmentation mask this step can be bypassed using the `--skip_ilastik` parameter in which case the composite `tiff` generated in step 3 will be used in subsequent steps instead.

5. Use probability/composite `tiff` and pre-processed full stack `tiff` for segmentation to generate a single cell mask as `tiff`, and subsequently overlay cell mask onto full stack `tiff` to generate single cell expression data in `csv` file ([CellProfiler](https://cellprofiler.org/)).

## Quick Start

i. Install [`nextflow`](https://nf-co.re/usage/installation)

ii. Install one of [`docker`](https://docs.docker.com/engine/installation/) or [`singularity`](https://www.sylabs.io/guides/3.0/user-guide/)

iii. Download the pipeline and test it on a minimal dataset with a single command

```bash
nextflow run nf-core/imcyto -profile test,<docker/singularity/institute>
```

> Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile institute` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.

iv. Start running your own analysis!

<!-- TODO nf-core: Update the default command above used to run the pipeline -->

```bash
nextflow run nf-core/imcyto \
    --input "./inputs/*.mcd" \
    --metadata './inputs/metadata.csv' \
    --full_stack_cppipe './plugins/full_stack_preprocessing.cppipe' \
    --ilastik_stack_cppipe './plugins/ilastik_stack_preprocessing.cppipe' \
    --segmentation_cppipe './plugins/segmentation.cppipe' \
    --ilastik_training_ilp './plugins/ilastik_training_params.ilp' \
    --plugins './plugins/cp_plugins/' \
    -profile <docker/singularity/institute>
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The nf-core/imcyto pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

## Credits

The pipeline was originally written by [The Bioinformatics & Biostatistics Group](https://www.crick.ac.uk/research/science-technology-platforms/bioinformatics-and-biostatistics/) for use at [The Francis Crick Institute](https://www.crick.ac.uk/), London.

The pipeline was developed by [Harshil Patel](mailto:harshil.patel@crick.ac.uk) and [Nourdine Bah](mailto:nourdine.bah@crick.ac.uk) in collaboration with [Karishma Valand](mailto:karishma.valand@crick.ac.uk), [Febe van Maldegem](mailto:febe.vanmaldegem@crick.ac.uk), [Emma Colliver](mailto:emma.colliver@crick.ac.uk) and [Mihaela Angelova](mailto:mihaela.angelova@crick.ac.uk).

Many thanks to others who contributed as a result of the Crick Data Challenge (Jan 2019) - Gavin Kelly, Becky Saunders, Katey Enfield, Alix Lemarois, Nuria Folguera Blasco, Andre Altmann.

It would not have been possible to develop this pipeline without the guidelines, scripts and plugins provided by the [Bodenmiller Lab](http://www.bodenmillerlab.com/). Thank you too!

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on [Slack](https://nfcore.slack.com/channels/imcyto) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citation

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nf-core/imcyto for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` pre-print as follows:  
> Ewels PA, Peltzer A, Fillinger S, Alneberg JA, Patel H, Wilm A, Garcia MU, Di Tommaso P, Nahnsen S. **nf-core: Community curated bioinformatics pipelines**. *bioRxiv*. 2019. p. 610741. [doi: 10.1101/610741](https://www.biorxiv.org/content/10.1101/610741v1).

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
