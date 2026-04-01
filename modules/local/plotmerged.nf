process PLOT_MERGED_HEATMAP {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(mergers)

    output:
    path("read-overlap-heatmap.pdf"), emit: mergers_plot
    path("read-overlap-heatmap.RDS"), emit: mergers_rds

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    plot_merged_heatmap.R \\
        --mergers ${mergers} \\
        --min_asv_len ${params.min_asv_len} \\
        --max_asv_len ${params.max_asv_len}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
