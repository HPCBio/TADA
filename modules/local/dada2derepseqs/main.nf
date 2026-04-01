process DADA2_DEREP_SEQS {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.R[12].derep.RDS"), emit: derep_rds
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rev_arg = meta.single_end ? "" : "--rev ${reads[1]}"
    // TODO: maybe we check this status
    """
    dada2_derep_seqs.R \\
        --fwd ${reads[0]} \\
        ${rev_arg} \\
        --sample_id ${meta.id}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    """
}
