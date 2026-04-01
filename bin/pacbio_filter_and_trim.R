#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(Biostrings))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--reads", type = "character", help = "Input FASTQ file"),
    make_option("--sample_id", type = "character", help = "Sample ID used for output file naming"),
    make_option("--maxEE_for", type = "numeric", default = 2,
        help = "Maximum expected errors [default %default]"),
    make_option("--maxN", type = "integer", default = 0,
        help = "Maximum number of Ns allowed [default %default]"),
    make_option("--max_read_len", type = "integer", default = Inf,
        help = "Maximum read length [default Inf]"),
    make_option("--min_read_len", type = "integer", default = 20,
        help = "Minimum read length [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("reads", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

out2 <- filterAndTrim(
    fwd         = opt$reads,
    filt        = paste0(opt$sample_id, ".R1.trim.fastq.gz"),
    maxEE       = opt$maxEE_for,
    maxN        = opt$maxN,
    maxLen      = opt$max_read_len,
    minLen      = opt$min_read_len,
    compress    = TRUE,
    verbose     = TRUE,
    multithread = opt$ncpus
)

# Change input read counts to actual raw read counts
write.csv(out2, paste0(opt$sample_id, ".trimmed.txt"))
