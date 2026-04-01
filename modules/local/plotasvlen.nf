process PLOT_ASV_DIST {
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqtab)
    path(seqs)

    output:
    path("asv-length-distribution.pdf"), emit: length_plot
    path("asv-length-distribution.RDS"), emit: length_RDS

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    plot_asv_length.R ${seqtab} ${seqs}
    """

    // stub:
    // def args = task.ext.args ?: ''
    
    // """
    // """
}
