process PHANGORN {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(aln)

    output:
    path("unrooted.phangorn.RDS"), emit: treeRDS
    path("unrooted.phangorn.newick"), emit: tree
    path("unrooted.phangorn.GTR.newick"), emit: treeGTR

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    phangorn_tree.R ${aln}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
