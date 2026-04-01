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
    root_tree.R \\
        --tree ${tree} \\
        --tree_tool ${tree_tool}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
