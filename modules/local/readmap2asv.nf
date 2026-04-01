process DADA2_READMAP2ASV {

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(readmap)

    output:
    path("asvs.fna"), emit: asvs

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    readmap2asv.R ${readmap}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
