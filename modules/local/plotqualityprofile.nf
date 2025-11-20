process PLOT_QUALITY_PROFILE {
    tag "$meta.id"
    label 'process_low'

    // TODO: pin to a versioned docker instance
    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.pdf"), emit: pdf
    tuple val(meta), path("*.RDS"), emit: rds

    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    plot_quality_profile.R --id ${meta.id} --session
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.PDF
    """
}
