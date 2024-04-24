process CELLPROFILER {
    tag "${meta.id}.${meta.roi}"
    label 'process_high'

    container "docker.io/cellprofiler/cellprofiler:4.2.1"

    input:
    tuple val(meta), path(tiff)
    path cppipe
    path plugin_dir
    path ctiff

    output:
    tuple val(meta), path("${prefix}*.tiff"), emit: tiff
    tuple val(meta), path("${prefix}*.csv") , emit: csv, optional: true
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ? task.ext.prefix.replaceAll("\\s","") : "${meta.id}"
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
