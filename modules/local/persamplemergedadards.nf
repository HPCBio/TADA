// TODO: this module needs to be renamed, the current name is 
// not technically correct and confusing with other outputs
// The main purposes are two-fold: 
// 1) combine the two denoised outputs for read tracking, and 
// 2) to generate prior R1 and R2 (if present) sequences for later

process PER_SAMPLE_MERGE {
    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(dds)
    val(stage)

    output:
    path("all.dd.${stage}.*.RDS"), emit: inferred // to readtracking
    path("priors.${stage}.R1.fna"), optional: true, emit: priors_for
    path("priors.${stage}.R2.fna"), optional: true, emit: priors_rev

    when:
    task.ext.when == null || task.ext.when

    script:
    def dadaOpts = params.dada_opts ? "${params.dada_opts}" : ""
    """
    per_sample_merge_dada_rds.R \\
        --stage ${stage} \\
        --id_type ${params.id_type} \\
        --dada_opts "${dadaOpts}"
    """
}