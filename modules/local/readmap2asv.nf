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
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))

    readmap <- readRDS("${readmap}")

    # Generate ASV FASTA
    asvs <- DNAStringSet(readmap\$seq)
    names(asvs) <- readmap\$id
    writeXStringSet(asvs, file="asvs.fna")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
