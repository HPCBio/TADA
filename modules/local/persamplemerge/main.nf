process PER_SAMPLE_MERGE {
    tag "$meta.id"
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(dds), path(dereps)
    val(stage)

    output:
    tuple val(meta), path("${meta.id}.${stage}.merged.RDS"), emit: merged_reads

    when:
    meta.single_end == false && (task.ext.when == null || task.ext.when)

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    per_sample_merge.R \\
        --dd_fwd ${dds[0]} \\
        --dd_rev ${dds[1]} \\
        --derep_fwd ${dereps[0]} \\
        --derep_rev ${dereps[1]} \\
        --sample_id ${meta.id} \\
        --stage ${stage} \\
        --min_overlap ${params.min_overlap} \\
        --max_mismatch ${params.max_mismatch} \\
        --trim_overhang ${params.trim_overhang} \\
        --just_concatenate ${params.just_concatenate}
    """
}
