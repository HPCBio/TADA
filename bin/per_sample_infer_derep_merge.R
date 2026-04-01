#!/usr/bin/env Rscript
# TODO: Remove!!! This module is slated for removal per the TODO in the .nf file
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(Biostrings))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--derep_fwd", type = "character", help = "Forward derep RDS file"),
    make_option("--derep_rev", type = "character", default = "null",
        help = "Reverse derep RDS file; omit or 'null' for single-end"),
    make_option("--sample_id", type = "character", help = "Sample ID used for output file naming"),
    make_option("--stage", type = "character", default = "1",
        help = "Stage label used in output filenames [default %default]"),
    make_option("--priors_fwd", type = "character", default = "null",
        help = "Forward priors FASTA file; omit or 'null' if no priors"),
    make_option("--priors_rev", type = "character", default = "null",
        help = "Reverse priors FASTA file; omit or 'null' if no priors"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a key=value string passed to setDadaOpt()"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("derep_fwd", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

set.seed(100)

getPriors <- function(x) {
    priors <- readDNAStringSet(x) |> as.vector() |> unname()
    return(priors)
}

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

cat("Processing:", opt$sample_id, "\n")

errF <- readRDS("errors.R1.RDS")
derepF <- readRDS(opt$derep_fwd)

paramsF <- list(
    derep = derepF,
    err = errF,
    multithread = opt$ncpus,
    pool = FALSE
)

if (!is.null(opt$priors_fwd) && opt$priors_fwd != "null" && file.size(opt$priors_fwd) > 0) {
    paramsF$priors <- getPriors(opt$priors_fwd)
}

ddF <- do.call(dada, paramsF)
saveRDS(ddF, paste0(opt$sample_id, ".dd.", opt$stage, ".R1.RDS"))

if (file.exists("errors.R2.RDS") && !is.null(opt$derep_rev) && opt$derep_rev != "null") {
    errR <- readRDS("errors.R2.RDS")
    derepR <- readRDS(opt$derep_rev)
    paramsR <- list(
        derep = derepR,
        err = errR,
        multithread = opt$ncpus,
        pool = FALSE
    )

    if (!is.null(opt$priors_rev) && opt$priors_rev != "null" && file.size(opt$priors_rev) > 0) {
        paramsR$priors <- getPriors(opt$priors_rev)
    }

    message("DADA2 params, R2:", paramsR, "\n")
    ddR <- do.call(dada, paramsR)
    saveRDS(ddR, paste0(opt$sample_id, ".dd.", opt$stage, ".R2.RDS"))
} else {
    # yes this is a little silly (it's the same as the dd.R1.RDS above).
    # But it does make the logical flow through this channel easier
    # TODO: check this line!!!
    saveRDS(ddF, paste(opt$sample_id, opt$stage, "R1.RDS", sep = "."))
}
