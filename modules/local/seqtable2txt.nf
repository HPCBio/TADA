process DADA2_SEQTABLE2TEXT {

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqtab)

    output:
    path("seqtab.qiime2.txt"), emit: seqtab2qiime
    path("*.txt")
    path("seqtab.RDS"), emit: seqtab_rds

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    seqtable2txt.R ${seqtab}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
