#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(phangorn))
suppressPackageStartupMessages(library(ape))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--tree", type = "character", help = "Input Newick tree file"),
    make_option("--tree_tool", type = "character", default = "phangorn",
        help = "Tree tool label used in output filenames [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$tree)) stop("--tree is required")

tree <- read.tree(file = opt$tree)

midtree <- midpoint(tree)

write.tree(midtree, file = paste0("rooted.", opt$tree_tool, ".newick"))
saveRDS(midtree, paste0("rooted.", opt$tree_tool, ".RDS"))
saveRDS(tree, paste0("unrooted.", opt$tree_tool, ".RDS"))
