process DADA2_POOLED_INFER {
    tag "${readmode}: ${params.pool}"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), path(err), path(filts)

    

    output:
    tuple val(readmode), path("all.dd.${readmode}.RDS"), emit: inferred
    path("dada2.denoised.pooled.${readmode}.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def dadaOpts = params.dada_opts ? "${params.dada_opts}" : ""
    """
    dada2_pooled_infer.R \\
        --readmode ${readmode} \\
        --err ${err} \\
        --pool ${params.pool} \\
        --dada_opts "${dadaOpts}" \\
        --platform ${params.platform} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    """
    # add some real stuff here
    touch all.dd.${readmode}.RDS
    """
}
