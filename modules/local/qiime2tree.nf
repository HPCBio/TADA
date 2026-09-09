process QIIME2_TREE {

    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(unrooted)
    path(rooted)

    output:
    path("unrooted_tree.qza"), emit: unrooted_qza
    path("rooted_tree.qza"), emit: rooted_qza
    path("versions.yml"), emit: versions
    // path("*.qzv"), emit: tree_qzv

    when:
    task.ext.when == null || task.ext.when 

    script:
    def args = task.ext.args ?: ''
    """
    qiime tools import \
        --input-path ${unrooted} \
        --output-path unrooted_tree.qza \
        --type 'Phylogeny[Unrooted]'

    qiime tools import \
        --input-path ${rooted} \
        --output-path rooted_tree.qza \
        --type 'Phylogeny[Rooted]'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch unrooted_tree.qza rooted_tree.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS    
    """
}
