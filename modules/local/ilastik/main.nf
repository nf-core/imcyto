process ILASTIK {
    tag "${meta.id}.${meta.roi}"
    label 'process_medium'

    container "docker.io/ilastik/ilastik-from-binary:1.4.0b13"

    input:
    tuple val(meta), path(tiff)
    path training_ilp

    output:
    tuple val(meta), path("*.tiff"), emit: tiff
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp $training_ilp ilastik_params.ilp

    /ilastik-release/run_ilastik.sh \\
        --headless \\
        --project=ilastik_params.ilp \\
        --output_format="tiff sequence" \\
        --output_filename_format=./{nickname}_{result_type}_{slice_index}.tiff \\
        --logfile ./ilastik.log.txt \\
        $args \\
        $tiff

    rm ilastik_params.ilp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ilastik: \$(/ilastik-release/bin/python -c "import ilastik; print(ilastik.__version__)")
    END_VERSIONS
    """
}
