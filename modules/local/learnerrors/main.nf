process DADA2_LEARN_ERRORS {
    tag "${params.platform} ${params.learnerrors_function} ${readmode}"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), path(reads)

    output:
    tuple val(readmode), path("errors.${readmode}.RDS"), emit: error_models
    path("${readmode}*.err.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    // Move platform-specific settings here?
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def learnOpts = params.learnerrors_opts ? "--learnerrors_opts '${params.learnerrors_opts}'" : ""
    def customCode = params.learnerrors_custom_code ? "--custom_code ${params.learnerrors_custom_code}" : ""
    """
    learn_errors.R \\
        --readmode ${readmode} \\
        --errfunc ${params.learnerrors_function} \\
        ${customCode} \\
        --quality_bins "${params.learnerrors_quality_bins}" \\
        --dada_opts "${params.dada_opts}" \\
        ${learnOpts} \\
        --quality_binning ${params.quality_binning} \\
        --random_seed ${params.random_seed} \\
        --ncpus ${task.cpus}
    """
}
