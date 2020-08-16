# nf-core/imcyto: Usage

<<<<<<< HEAD
## Table of contents

* [Table of contents](#table-of-contents)
* [Introduction](#introduction)
* [Running the pipeline](#running-the-pipeline)
  * [Updating the pipeline](#updating-the-pipeline)
  * [Reproducibility](#reproducibility)
* [Main arguments](#main-arguments)
  * [`-profile`](#-profile)
  * [`--input`](#--input)
  * [`--metadata`](#--metadata)
  * [`--full_stack_cppipe`](#--full_stack_cppipe)
  * [`--ilastik_stack_cppipe`](#--ilastik_stack_cppipe)
  * [`--segmentation_cppipe`](#--segmentation_cppipe)
  * [`--ilastik_training_ilp`](#--ilastik_training_ilp)
  * [`--compensation_tiff`](#--compensation_tiff)
  * [`--skip_ilastik`](#--skip_ilastik)
  * [`--plugins`](#--plugins)
* [Job resources](#job-resources)
  * [Automatic resubmission](#automatic-resubmission)
  * [Custom resource requests](#custom-resource-requests)
* [AWS Batch specific parameters](#aws-batch-specific-parameters)
  * [`--awsqueue`](#--awsqueue)
  * [`--awsregion`](#--awsregion)
  * [`--awscli`](#--awscli)
* [Other command line parameters](#other-command-line-parameters)
  * [`--outdir`](#--outdir)
  * [`--publish_dir_mode`](#--publish_dir_mode)
  * [`--email`](#--email)
  * [`--email_on_fail`](#--email_on_fail)
  * [`-name`](#-name)
  * [`-resume`](#-resume)
  * [`-c`](#-c)
  * [`--custom_config_version`](#--custom_config_version)
  * [`--custom_config_base`](#--custom_config_base)
  * [`--max_memory`](#--max_memory)
  * [`--max_time`](#--max_time)
  * [`--max_cpus`](#--max_cpus)
  * [`--plaintext_email`](#--plaintext_email)
  * [`--monochrome_logs`](#--monochrome_logs)

## Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
=======
## Introduction

<!-- TODO nf-core: Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website. -->
>>>>>>> TEMPLATE

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
<<<<<<< HEAD
nextflow run nf-core/imcyto \
    --input "./inputs/*.mcd" \
    --metadata './inputs/metadata.csv' \
    --full_stack_cppipe './plugins/full_stack_preprocessing.cppipe' \
    --ilastik_stack_cppipe './plugins/ilastik_stack_preprocessing.cppipe' \
    --segmentation_cppipe './plugins/segmentation.cppipe' \
    --ilastik_training_ilp './plugins/ilastik_training_params.ilp' \
    --plugins './plugins/cp_plugins/' \
    -profile <docker/singularity>
=======
nextflow run nf-core/imcyto --input '*_R{1,2}.fastq.gz' -profile docker
>>>>>>> TEMPLATE
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/imcyto
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/imcyto releases page](https://github.com/nf-core/imcyto/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity) - see below.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended.

* `docker`
  * A generic configuration profile to be used with [Docker](https://docker.com/)
  * Pulls software from Docker Hub: [`nfcore/imcyto`](https://hub.docker.com/r/nfcore/imcyto/)
* `singularity`
<<<<<<< HEAD
  * A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
  * Pulls software from DockerHub: [`nfcore/imcyto`](http://hub.docker.com/r/nfcore/imcyto/)
=======
  * A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
  * Pulls software from Docker Hub: [`nfcore/imcyto`](https://hub.docker.com/r/nfcore/imcyto/)
* `conda`
  * Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker or Singularity.
  * A generic configuration profile to be used with [Conda](https://conda.io/docs/)
  * Pulls most software from [Bioconda](https://bioconda.github.io/)
>>>>>>> TEMPLATE
* `test`
  * A profile with a complete configuration for automated testing
  * Includes links to test data so needs no other parameters

<<<<<<< HEAD
### `--input`

Path to input data file(s) (globs must be surrounded with quotes). Currently supported formats are `*.mcd`, `*.tiff` and `*.txt`.

```bash
--input "./mcd/*.mcd"
```

### `--metadata`

Path to metadata `csv` file indicating which images to merge in full and/or Ilastik stack. The file should only contain 3 columns i.e. 'metal', 'full_stack' and 'ilastik_stack'. The `metal` column should contain all the metals used in your antibody panel. The `full_stack` and `ilastik_stack` entries should be `1` or `0` to indicate whether to include or exclude a metal for a given stack, respectively. See [`metadata.csv`](https://github.com/nf-core/test-datasets/blob/imcyto/inputs/metadata.csv) for an example.

```bash
--metadata 'metadata.csv'
```

### `--full_stack_cppipe`

Path to CellProfiler pipeline file required to create full stack (`cppipe` format).

```bash
--full_stack_cppipe './plugins/full_stack_preprocessing.cppipe'
```

### `--ilastik_stack_cppipe`

Path to CellProfiler pipeline file required to create Ilastik stack (`cppipe` format).

```bash
--ilastik_stack_cppipe './plugins/ilastik_stack_preprocessing.cppipe'
```

### `--segmentation_cppipe`

Path to CellProfiler pipeline file required for segmentation (`cppipe` format).

```bash
--segmentation_cppipe './plugins/segmentation.cppipe'
```

### `--ilastik_training_ilp`

Path to parameter file required by Ilastik (`ilp` format).

```bash
--ilastik_training_ilp './plugins/ilastik_training_params.ilp'
```

### `--compensation_tiff`

Path to `tiff` file for compensation analysis during CellProfiler preprocessing steps.

```bash
--compensation_tiff './tiff/compensation.tiff'
```

### `--skip_ilastik`

Flag to skip Ilastik processing step.

### `--plugins`

Path to directory with plugin files required for CellProfiler.

```bash
--plugins './cellprofiler/plugins/'
```

Default: `assets/plugins`

## Job resources

### Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files hosted at [`nf-core/configs`](https://github.com/nf-core/configs/tree/master/conf) for examples.
=======
### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

#### Custom resource requests

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

Whilst these default requirements will hopefully work for most people with most data, you may find that you want to customise the compute resources that the pipeline requests. You can do this by creating a custom config file. For example, to give the workflow process `star` 32GB of memory, you could use the following config:

```nextflow
process {
  withName: star {
    memory = 32.GB
  }
}
```

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information.
>>>>>>> TEMPLATE

If you are likely to be running `nf-core` pipelines regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter (see definition below). You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

### Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

#### Nextflow memory requirements

<<<<<<< HEAD
## Other command line parameters

### `--outdir`

The output directory where the results will be saved.

### `--publish_dir_mode`

Value passed to Nextflow [`publishDir`](https://www.nextflow.io/docs/latest/process.html#publishdir) directive for publishing results in the output directory. Available: 'symlink', 'rellink', 'link', 'copy', 'copyNoFollow' and 'move' (Default: 'copy').

### `--email`

Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.

### `--email_on_fail`

This works exactly as with `--email`, except emails are only sent if the workflow is not successful.

### `-name`

Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML / e-mail (always).

**NB:** Single hyphen (core Nextflow option)

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`

Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

Note - you can use this to override pipeline defaults.

### `--custom_config_version`

Provide git commit id for custom Institutional configs hosted at `nf-core/configs`. This was implemented for reproducibility purposes. Default: `master`.

```bash
## Download and use config file with following git commid id
--custom_config_version d52db660777c4bf36546ddb188ec530c3ada1b96
```

### `--custom_config_base`

If you're running offline, nextflow will not be able to fetch the institutional config files
from the internet. If you don't need them, then this is not a problem. If you do need them,
you should download the files from the repo and tell nextflow where to find them with the
`custom_config_base` option. For example:
=======
In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):
>>>>>>> TEMPLATE

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
<<<<<<< HEAD

> Note that the nf-core/tools helper package has a `download` command to download all required pipeline
> files + singularity containers + institutional configs in one go for you, to make this process easier.

### `--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### `--max_time`

Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--plaintext_email`

Set to receive plain-text e-mails instead of HTML formatted.

### `--monochrome_logs`

Set to disable colourful command line output and live life in monochrome.
=======
>>>>>>> TEMPLATE
