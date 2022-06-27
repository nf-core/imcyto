process CELLPROFILER {
    tag "${meta.id}.${meta.roi}"
    label 'process_high'

    container "cellprofiler/cellprofiler:3.1.9"

    input:
    tuple val(meta), path(tiff)
    path cppipe
    path ctiff
    path plugin_dir

    output:
    tuple val(meta), path("${prefix}/*"), emit: tiff
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"

    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellprofiler: \$(cellprofiler --version)
    END_VERSIONS
    """
}
