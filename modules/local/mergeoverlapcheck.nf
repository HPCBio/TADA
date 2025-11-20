process MERGE_OVERLAP_CHECK {
    tag 'Overlap Stats'
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(logs)

    output:
    path("all_mergedstats.tsv"), emit: overlap_check_stats
    // path "versions.yml"           , emit: versions

    when:
    !params.skip_merging_check || task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    MergeCheck_Table.R
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}