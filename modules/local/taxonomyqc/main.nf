process TAXONOMY_QC {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_rds)
    
    output:
    path("assigned_taxonomy.pdf"), emit: taxtab_rds
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    taxonomy_qc.R ${taxtab_rds}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}