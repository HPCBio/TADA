#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--dd_fwd", type = "character", help = "Forward dada RDS file"),
    make_option("--dd_rev", type = "character", help = "Reverse dada RDS file"),
    make_option("--derep_fwd", type = "character", help = "Forward derep RDS file"),
    make_option("--derep_rev", type = "character", help = "Reverse derep RDS file"),
    make_option("--sample_id", type = "character", help = "Sample ID used for output file naming"),
    make_option("--stage", type = "character", default = "1",
        help = "Stage label used in output filenames [default %default]"),
    make_option("--min_overlap", type = "integer", default = 12,
        help = "Minimum overlap for merging [default %default]"),
    make_option("--max_mismatch", type = "integer", default = 0,
        help = "Maximum mismatches in overlap region [default %default]"),
    make_option("--trim_overhang", type = "logical", default = FALSE,
        help = "Trim overhangs after merging [default %default]"),
    make_option("--just_concatenate", type = "logical", default = FALSE,
        help = "Concatenate reads instead of merging [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("dd_fwd", "dd_rev", "derep_fwd", "derep_rev", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

ddF <- readRDS(opt$dd_fwd)
ddR <- readRDS(opt$dd_rev)
derepF <- readRDS(opt$derep_fwd)
derepR <- readRDS(opt$derep_rev)

merger <- mergePairs(ddF, derepF, ddR, derepR,
    returnRejects = TRUE,
    minOverlap = opt$min_overlap,
    maxMismatch = opt$max_mismatch,
    trimOverhang = opt$trim_overhang,
    justConcatenate = opt$just_concatenate
)

saveRDS(merger, paste0(opt$sample_id, ".", opt$stage, ".merged.RDS"))
