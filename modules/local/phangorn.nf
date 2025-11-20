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
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(phangorn))

    phang.align <- read.phyDat("${aln}",
                                format = "fasta",
                                type = "DNA")

    dm <- dist.ml(phang.align)
    treeNJ <- NJ(dm) # Note, tip order != sequence order
    fit = pml(treeNJ, data=phang.align)
    write.tree(fit\$tree, file = "unrooted.phangorn.newick")

    ## negative edges length changed to 0!
    fitGTR <- update(fit, k=4, inv=0.2)
    fitGTR <- optim.pml(fitGTR, model="GTR", optInv=TRUE, optGamma=TRUE,
                          rearrangement = "stochastic", control = pml.control(trace = 0))
    saveRDS(fitGTR, "unrooted.phangorn.RDS")
    write.tree(fitGTR\$tree, file = "unrooted.phangorn.GTR.newick")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
