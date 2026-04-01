process DADA2_TAXTABLE2TEXT {

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_rds)
    path(metrics_rds)

    output:
    path("taxtab.txt"), emit: taxtab
    path("metrics.txt"), emit: metrics
    path("taxtab.RDS"), emit: taxtab_final_rds
    path("taxmetrics.RDS"), emit: taxmetrics_final_rds

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    taxtable2txt.R ${taxtab_rds} ${metrics_rds}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
