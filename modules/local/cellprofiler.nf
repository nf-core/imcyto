/*
 * STEP 2: Preprocess full stack images with CellProfiler
 */
process PREPROCESS_FULL_STACK {
    tag "${name}.${roi}"
    label 'process_medium'
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: params.publish_dir_mode,
        saveAs: { filename ->
                    if (filename.indexOf("version.txt") > 0) null
                    else filename
                }

    input:
    tuple val(name), val(roi), path(tiff) from ch_full_stack_tiff
    path ctiff from ch_compensation_full_stack.collect().ifEmpty([])
    path cppipe from ch_full_stack_cppipe
    path plugin_dir from ch_preprocess_full_stack_plugin.collect()

    output:
    tuple val(name), val(roi), path("full_stack/*") into ch_preprocess_full_stack_tiff
    path "*version.txt" into ch_cellprofiler_version

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./full_stack \\
        --log-level DEBUG \\
        --temporary-directory ./tmp

    cellprofiler --version > cellprofiler_version.txt
    """
}

/*
 * STEP 3: Preprocess Ilastik stack images with CellProfiler
 */
process PREPROCESS_ILASTIK_STACK {
    tag "${name}.${roi}"
    label 'process_medium'
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: params.publish_dir_mode

    input:
    tuple val(name), val(roi), path(tiff) from ch_ilastik_stack_tiff
    path ctiff from ch_compensation_ilastik_stack.collect().ifEmpty([])
    path cppipe from ch_ilastik_stack_cppipe
    path plugin_dir from ch_preprocess_ilastik_stack_plugin.collect()

    output:
    tuple val(name), val(roi), path("ilastik_stack/*") into ch_preprocess_ilastik_stack_tiff

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./ilastik_stack \\
        --log-level DEBUG \\
        --temporary-directory ./tmp
    """
}

/*
 * STEP 5: Segmentation with CellProfiler
 */
process SEGMENTATION {
    tag "${name}.${roi}"
    label 'process_high'
    publishDir "${params.outdir}/segmentation/${name}/${roi}", mode: params.publish_dir_mode

    input:
    tuple val(name), val(roi), path(tiff) from ch_preprocess_full_stack_tiff
    path cppipe from ch_segmentation_cppipe
    path plugin_dir from ch_segmentation_plugin.collect()

    output:
    path "*.{csv,tiff}"

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./ \\
        --log-level DEBUG \\
        --temporary-directory ./tmp
    """
}
