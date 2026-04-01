#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--fwd", type = "character", help = "Forward (R1) FASTQ file to sample"),
    make_option("--sample_id", type = "character", help = "Sample ID (used for output naming)"),
    make_option("--n_reads", type = "integer", default = 1000000,
        help = "Number of reads to sample [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("fwd", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

# Read just R1
l <- FastqSampler(opt$fwd,
    n = opt$n_reads,
    readerBlockSize = 1e4)

fq <- yield(l)
qual_matrix <- as(quality(fq), "matrix")
qual_df <- as.data.frame(qual_matrix)
qual_df$ReadID <- rownames(qual_df)
qual_long <- qual_df %>%
    pivot_longer(
        cols = -ReadID,
        names_to = "BasePosition",
        values_to = "QualityScore"
    ) %>%
    mutate(BasePosition = as.integer(gsub("V", "", BasePosition)))

binned_quals <- factor(qual_long$QualityScore) %>%
    levels() %>%
    as.integer()

# this assumes there are 10 or fewer bins
stopifnot(length(binned_quals) <= 10)

saveRDS(binned_quals, "quality_bins.RDS")
