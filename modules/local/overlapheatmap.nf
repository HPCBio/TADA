process OVERLAP_HEATMAP {
    tag "Overlap Heatmap"
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(merged_tables)

    output:
    path("MergedCheck_heatmap*.pdf"),     emit: overlap_check_pdf
    path("stats.RDS"), emit: overlap_check_rds
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    MergeCheck_Plot.R --forward ${params.for_primer} --reverse ${params.rev_primer}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch 
    """
}
