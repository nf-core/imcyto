/*
 * STEP 1: imctools
 */
process IMCTOOLS {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}/imctools/${name}", mode: params.publish_dir_mode,
        saveAs: { filename ->
            if (filename.indexOf("version.txt") > 0) null
            else filename
        }

    input:
    tuple val(name), path(mcd) from ch_mcd
    path metadata from ch_metadata

    output:
    tuple val(name), path("*/full_stack/*") into ch_full_stack_tiff
    tuple val(name), path("*/ilastik_stack/*") into ch_ilastik_stack_tiff
    path "*/*ome.tiff"
    path "*.csv"
    path "*version.txt" into ch_imctools_version

    script: // This script is bundled with the pipeline, in nf-core/imcyto/bin/
    """
    run_imctools.py $mcd $metadata
    pip show imctools | grep "Version" > imctools_version.txt
    """
}
