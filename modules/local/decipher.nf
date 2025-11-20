process DECIPHER {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqs)

    output:
    path("asvs.aligned.fna"), optional: true, emit: alignment

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(DECIPHER))

    seqs <- readDNAStringSet("${seqs}")
    alignment <- AlignSeqs(seqs,
               anchor=NA,
               processors = ${task.cpus})
    writeXStringSet(alignment, "asvs.aligned.fna")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
