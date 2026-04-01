#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(Biostrings))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--sample_id", type = "character", help = "Sample ID used for input/output file naming"),
    make_option("--single_end", type = "logical", default = FALSE,
        help = "Treat data as single-end [default %default]"),
    make_option("--maxEE_for", type = "numeric", default = 2,
        help = "Maximum expected errors for R1 [default %default]"),
    make_option("--maxEE_rev", type = "numeric", default = 2,
        help = "Maximum expected errors for R2 [default %default]"),
    make_option("--truncQ", type = "integer", default = 2,
        help = "Truncate at first quality score <= this value [default %default]"),
    make_option("--rmPhiX", type = "logical", default = TRUE,
        help = "Remove reads matching PhiX [default %default]"),
    make_option("--max_read_len", type = "integer", default = Inf,
        help = "Maximum read length [default Inf]"),
    make_option("--min_read_len", type = "integer", default = 20,
        help = "Minimum read length [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$sample_id)) stop("--sample_id is required")

out <- filterAndTrim(
    fwd      = paste0(opt$sample_id, ".R1.cutadapt.fastq.gz"),
    filt     = paste0(opt$sample_id, ".R1.filtered.fastq.gz"),
    rev      = if (opt$single_end) NULL else paste0(opt$sample_id, ".R2.cutadapt.fastq.gz"),
    filt.rev = if (opt$single_end) NULL else paste0(opt$sample_id, ".R2.filtered.fastq.gz"),
    maxEE    = if (opt$single_end) opt$maxEE_for else c(opt$maxEE_for, opt$maxEE_rev),
    truncQ   = opt$truncQ,
    rm.phix  = opt$rmPhiX,
    maxLen   = opt$max_read_len,
    minLen   = opt$min_read_len,
    compress = TRUE,
    verbose  = TRUE,
    multithread = opt$ncpus
)

# Change input read counts to actual raw read counts
colnames(out) <- c('cutadapt', 'filtered')
write.csv(out, paste0(opt$sample_id, ".trimmed.txt"))
