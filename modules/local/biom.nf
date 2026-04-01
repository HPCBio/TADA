process BIOM {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqtab) 
    path(taxtab)

    output:
    path("final.biom"), emit: biom

    when:
    task.ext.when == null || task.ext.when || params.toBIOM == true

    script:
    def args = task.ext.args ?: ''
    """
    dada2_biom.R ${seqtab} ${taxtab}
    """

    stub:
    def args = task.ext.args ?: ''
    """
    """
}
