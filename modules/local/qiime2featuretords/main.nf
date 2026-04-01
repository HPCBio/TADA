process QIIME2_FEATURE_TO_RDS {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_qiime2_tsv)
    
    output:
    path("taxtab.qiime2.RDS"), emit: taxtab_rds
    path("confidence.qiime2.RDS"), emit: metrics_rds
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    qiime2_feature_to_rds.R ${taxtab_qiime2_tsv}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}