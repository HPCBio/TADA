process ROOT_TREE {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(tree)
    val(tree_tool)

    output:
    path("rooted.${tree_tool}.newick"), emit: rooted_tree
    path("rooted.${tree_tool}.RDS"), emit: rooted_tree_RDS
    path("unrooted.${tree_tool}.RDS"), emit: unrooted_tree_RDS

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(phangorn))
    suppressPackageStartupMessages(library(ape))

    tree <- read.tree(file = "${tree}")

    midtree <- midpoint(tree)

    write.tree(midtree, file = "rooted.${tree_tool}.newick")
    saveRDS(midtree, "rooted.${tree_tool}.RDS")
    saveRDS(tree, "unrooted.${tree_tool}.RDS")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
