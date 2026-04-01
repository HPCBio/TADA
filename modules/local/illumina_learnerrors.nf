// TODO: change to DADA2_ILLUMINA_LEARN_ERRORS
process ILLUMINA_DADA2_LEARN_ERRORS {
    tag "$readmode"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), file(reads)

    output:
    tuple val(readmode), file("errors.${readmode}.RDS"), emit: error_models
    path("${readmode}.err.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def dadaOpts = !params.dada_opts.isEmpty() ? params.dada_opts.collect{k,v->"$k=$v"}.join(", ") : ""
    """
    illumina_learn_errors.R \\
        --readmode ${readmode} \\
        --dada_opts "${dadaOpts}" \\
        --quality_binning ${params.quality_binning} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    # TODO: make a proper stub
    """
}
