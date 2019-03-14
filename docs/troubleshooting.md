# nf-core/imcyto: Troubleshooting

<!-- TODO nf-core: Change this documentation if these parameters/errors are not relevant for your workflow -->

## Input files not found

If the pipeline is not able to find all the files you have specified then something is wrong with your input file declaration

1. The path must be enclosed in quotes (`'` or `"`)
2. The path must have at least one `*` wildcard character (if you are trying to run the pipeline for multiple files)

If the pipeline can't find your files then you will get the following error

```
ERROR ~ MCD file not found: *.mcd
```

## Data organization
The pipeline can't take a list of multiple input files - it takes a glob expression. If your input files are scattered in different paths then we recommend that you generate a directory with symlinked files.

## Extra resources and getting help
If you still have an issue with running the pipeline then feel free to contact us.
Have a look at the [pipeline website](https://github.com/nf-core/imcyto) to find out how.

If you have problems that are related to Nextflow and not our pipeline then check out the [Nextflow gitter channel](https://gitter.im/nextflow-io/nextflow) or the [google group](https://groups.google.com/forum/#!forum/nextflow).
