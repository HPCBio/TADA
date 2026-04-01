#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--readmode", type = "character", help = "Read mode label (e.g. R1, R2)"),
    make_option("--err", type = "character", help = "Error model RDS file"),
    make_option("--pool", type = "character", default = "FALSE",
        help = "Pooling mode: TRUE, FALSE, or pseudo [default %default]"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a key=value string passed to setDadaOpt()"),
    make_option("--platform", type = "character", default = "illumina",
        help = "Sequencing platform: illumina or pacbio [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("readmode", "err")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

getN <- function(x) sum(getUniques(x))

set.seed(100)

cat("Processing all samples\n")

err <- readRDS(opt$err)

# 'pool' is a weird flag: either 'pseudo' (string), or T/F (bool)
pool <- opt$pool
if (pool != "pseudo") {
    pool <- as.logical(pool)
}

# Determine trim pattern from readmode (R1 -> _1, R2 -> _2, else no suffix)
trimmode <- sub("R", "", opt$readmode)  # "1" or "2"
filts <- list.files('.', pattern = paste0("(_", trimmode, ")?.trim.fastq.gz"))
names(filts) <- gsub(paste0("(_", trimmode, ")?.trim.fastq.gz"), "", filts)

cat(paste0("Denoising ", opt$readmode, " reads: pool:", pool, "\n"))

dada_args <- list(filts, err = err, multithread = opt$ncpus, pool = pool)

if (opt$platform == "pacbio") {
    dada_args$BAND_SIZE <- 32L
}

dds <- do.call(dada, dada_args)

saveRDS(dds, paste0("all.dd.", opt$readmode, ".RDS"))

tracking_dds <- as.data.frame(sapply(dds, getN))
colnames(tracking_dds) <- c(paste0("dada2.denoised.pooled.", opt$readmode))
tracking_dds <- tracking_dds %>%
    as_tibble() %>%
    mutate(SampleID = rownames(tracking_dds), .before = 1)
write_csv(tracking_dds, paste0("dada2.denoised.pooled.", opt$readmode, ".csv"))
