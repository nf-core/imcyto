<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-imcyto_logo_dark.png">
    <img alt="nf-core/imcyto" src="docs/images/nf-core-imcyto_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/imcyto/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/imcyto/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/imcyto/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/imcyto/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/imcyto/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.3865430-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.3865430)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/imcyto)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23imcyto-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/imcyto)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nfcore/imcyto** is a bioinformatics analysis pipeline used for image segmentation and extraction of single cell expression data. This pipeline was generated for Imaging Mass Cytometry data, however, it is flexible enough to be applicable to other types of imaging data e.g. immunofluorescence/immunohistochemistry data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources. The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/imcyto/results).

## Pipeline summary

1. Split image acquisition output files (`mcd`, `ome.tiff` or `txt`) by ROI and convert to individual `tiff` files for channels with names matching those defined in user-provided `metadata.csv` file. Full and ilastik stacks will be generated separately for all channels being analysed in single cell expression analysis, and for channels being used to generate the cell mask, respectively ([imctools](https://github.com/BodenmillerGroup/imctools)).

2. Apply pre-processing filters to full stack `tiff` files ([CellProfiler](https://cellprofiler.org/)).

3. Use selected `tiff` files in ilastik stack to generate a composite RGB image representative of the plasma membranes and nuclei of all cells ([CellProfiler](https://cellprofiler.org/)).

4. Use composite cell map to apply pixel classification for membranes, nuclei or background, and save probabilities map as `tiff` ([Ilastik](https://www.ilastik.org/)). If CellProfiler modules alone are deemed sufficient to achieve a reliable segmentation mask this step can be bypassed using the `--skip_ilastik` parameter in which case the composite `tiff` generated in step 3 will be used in subsequent steps instead.

5. Use probability/composite `tiff` and pre-processed full stack `tiff` for segmentation to generate a single cell mask as `tiff`, and subsequently overlay cell mask onto full stack `tiff` to generate single cell expression data in `csv` file ([CellProfiler](https://cellprofiler.org/)).

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

```console
nextflow run nf-core/imcyto \
  -profile <docker/singularity/podman/shifter/charliecloud/conda/institute> \
  --input "./inputs/*.mcd" \
  --outdir <OUTDIR> \
  --metadata './inputs/metadata.csv' \
  --full_stack_cppipe './plugins/full_stack_preprocessing.cppipe' \
  --ilastik_stack_cppipe './plugins/ilastik_stack_preprocessing.cppipe' \
  --segmentation_cppipe './plugins/segmentation.cppipe' \
  --ilastik_training_ilp './plugins/ilastik_training_params.ilp' \
  --plugins_dir './plugins/cp_plugins/'
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/imcyto/usage) and the [parameter documentation](https://nf-co.re/imcyto/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/imcyto/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/imcyto/output).

## Credits

The pipeline was originally written by [The Bioinformatics & Biostatistics Group](https://www.crick.ac.uk/research/science-technology-platforms/bioinformatics-and-biostatistics/) for use at [The Francis Crick Institute](https://www.crick.ac.uk/), London.

The pipeline was developed by [Harshil Patel](mailto:harshil.patel@crick.ac.uk) and [Nourdine Bah](mailto:nourdine.bah@crick.ac.uk) in collaboration with [Karishma Valand](mailto:karishma.valand@crick.ac.uk), [Febe van Maldegem](mailto:febe.vanmaldegem@crick.ac.uk), [Emma Colliver](mailto:emma.colliver@crick.ac.uk) and [Mihaela Angelova](mailto:mihaela.angelova@crick.ac.uk).

Many thanks to others who contributed as a result of the Crick Data Challenge (Jan 2019) - Gavin Kelly, Becky Saunders, Katey Enfield, Alix Lemarois, Nuria Folguera Blasco, Andre Altmann.

It would not have been possible to develop this pipeline without the guidelines, scripts and plugins provided by the [Bodenmiller Lab](http://www.bodenmillerlab.com/). Thank you too!

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#imcyto` channel](https://nfcore.slack.com/channels/imcyto) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/imcyto for your analysis, please cite it using the following doi: [10.5281/zenodo.3865430](https://doi.org/10.5281/zenodo.3865430)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
