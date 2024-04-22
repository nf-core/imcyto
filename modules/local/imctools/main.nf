process IMCTOOLS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::imctools=1.0.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/imctools:1.0.5--py_0':
        'biocontainers/imctools:1.0.5--py_0' }"

    input:
    tuple val(meta), path(mcd)
    path metadata

    output:
    tuple val(meta), path("*/full_stack/*")   , emit: full_stack_tiff
    tuple val(meta), path("*/ilastik_stack/*"), emit: ilastik_stack
    tuple val(meta), path("*/*ome.tiff")      , emit: ome_tiff
    tuple val(meta), path("*.csv")            , emit: csv
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/imcyto/bin/
    """
    run_imctools.py \\
        $mcd \\
        $metadata

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        imctools: \$(pip show imctools | grep "Version" | sed 's/Version: //g')
    END_VERSIONS
    """
}
