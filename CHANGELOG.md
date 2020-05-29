# nf-core/imcyto: Changelog

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2020-05-29

Initial release of nf-core/imcyto, created with the [nf-core](http://nf-co.re/) template.

## Pipeline summary

1. Split image acquisition output files (`mcd`, `ome.tiff` or `txt`) by ROI and convert to individual `tiff` files for channels with names matching those defined in user-provided `metadata.csv` file. Full and ilastik stacks will be generated separately for all channels being analysed in single cell expression analysis, and for channels being used to generate the cell mask, respectively ([imctools](https://github.com/BodenmillerGroup/imctools)).

2. Apply pre-processing filters to full stack `tiff` files ([CellProfiler](https://cellprofiler.org/)).

3. Use selected `tiff` files in ilastik stack to generate a composite RGB image representative of the plasma membranes and nuclei of all cells ([CellProfiler](https://cellprofiler.org/)).

4. Use composite cell map to apply pixel classification for membranes, nuclei or background, and save probabilities map as `tiff` ([Ilastik](https://www.ilastik.org/)). If CellProfiler modules alone are deemed sufficient to achieve a reliable segmentation mask this step can be bypassed using the `--skip_ilastik` parameter in which case the composite `tiff` generated in step 3 will be used in subsequent steps instead.

5. Use probability/composite `tiff` and pre-processed full stack `tiff` for segmentation to generate a single cell mask as `tiff`, and subsequently overlay cell mask onto full stack `tiff` to generate single cell expression data in `csv` file ([CellProfiler](https://cellprofiler.org/)).
