#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(phangorn))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: phangorn_tree.R <alignment.fna>")

phang.align <- read.phyDat(args[1], format = "fasta", type = "DNA")

dm <- dist.ml(phang.align)
treeNJ <- NJ(dm) # Note, tip order != sequence order
fit <- pml(treeNJ, data = phang.align)
write.tree(fit$tree, file = "unrooted.phangorn.newick")

## negative edges length changed to 0!
fitGTR <- update(fit, k = 4, inv = 0.2)
fitGTR <- optim.pml(fitGTR, model = "GTR", optInv = TRUE, optGamma = TRUE,
                    rearrangement = "stochastic", control = pml.control(trace = 0))
saveRDS(fitGTR, "unrooted.phangorn.RDS")
write.tree(fitGTR$tree, file = "unrooted.phangorn.GTR.newick")
