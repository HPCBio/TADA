process PER_SAMPLE_TRACKING {
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(dds)
    val(stage)

    output:
    path("priors.${stage}.R1.fna"), optional: true, emit: for_priors
    path("priors.${stage}.R2.fna"), optional: true, emit: rev_priors
    path("all.dd.${stage}.*.RDS"), emit: inferred
    path("dada2.denoised.${stage}.*.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def dadaOpts = params.dada_opts ? "${params.dada_opts}" : ""
    """
    per_sample_tracking.R \\
        --stage ${stage} \\
        --id_type ${params.id_type} \\
        --dada_opts "${dadaOpts}"
    """
}
