// TODO: Remove!!!
process PER_SAMPLE_INFER {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(dereps)
    path(errs)
    // optional inputs
    path(fp, stageAs: "priors_R1")
    path(rp, stageAs: "priors_R2")
    val(stage)

    output:
    tuple val(meta), path("${meta.id}.dd.${stage}.R{1,2}.RDS"), emit: dds
    val(readmode), emit: readmode

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def dadaOpts = params.dada_opts ? "${params.dada_opts}" : ""
    def revDerep = dereps.size() > 1 ? "--derep_rev ${dereps[1]}" : ""
    def fwdPriors = fp.size() > 0 ? "--priors_fwd ${fp}" : ""
    def revPriors = rp.size() > 0 ? "--priors_rev ${rp}" : ""
    """
    per_sample_infer_derep_merge.R \\
        --derep_fwd ${dereps[0]} \\
        ${revDerep} \\
        --sample_id ${meta.id} \\
        --stage ${stage} \\
        ${fwdPriors} \\
        ${revPriors} \\
        --dada_opts "${dadaOpts}" \\
        --ncpus ${task.cpus}
    """
}
