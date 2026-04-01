#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--fwd", type = "character", help = "Forward (R1) input FASTQ file"),
    make_option("--fwd_out", type = "character", help = "Forward (R1) output filtered FASTQ filename"),
    make_option("--rev", type = "character", default = "null",
        help = "Reverse (R2) input FASTQ file; omit or 'null' for single-end"),
    make_option("--rev_out", type = "character", default = "null",
        help = "Reverse (R2) output filtered FASTQ filename; omit or 'null' for single-end"),
    make_option("--sample_id", type = "character", help = "Sample ID used for output report filename"),
    make_option("--trim_for", type = "integer", default = 0,
        help = "Nucleotides to trim from 5' end of R1 [default %default]"),
    make_option("--trim_rev", type = "integer", default = 0,
        help = "Nucleotides to trim from 5' end of R2 [default %default]"),
    make_option("--trunc_for", type = "integer", default = 0,
        help = "Truncate R1 reads to this length (0 = no truncation) [default %default]"),
    make_option("--trunc_rev", type = "integer", default = 0,
        help = "Truncate R2 reads to this length (0 = no truncation) [default %default]"),
    make_option("--maxEE_for", type = "numeric", default = 2,
        help = "Maximum expected errors for R1 [default %default]"),
    make_option("--maxEE_rev", type = "numeric", default = 2,
        help = "Maximum expected errors for R2 [default %default]"),
    make_option("--truncQ", type = "integer", default = 2,
        help = "Truncate at first quality score <= this value [default %default]"),
    make_option("--maxN", type = "integer", default = 0,
        help = "Maximum number of Ns allowed [default %default]"),
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
for (arg in c("fwd", "fwd_out", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

single_end <- is.null(opt$rev) || opt$rev == "null"

out <- filterAndTrim(
    fwd         = opt$fwd,
    filt        = opt$fwd_out,
    rev         = if (single_end) NULL else opt$rev,
    filt.rev    = if (single_end) NULL else opt$rev_out,
    trimLeft    = if (single_end) opt$trim_for else c(opt$trim_for, opt$trim_rev),
    truncLen    = if (single_end) opt$trunc_for else c(opt$trunc_for, opt$trunc_rev),
    maxEE       = if (single_end) opt$maxEE_for else c(opt$maxEE_for, opt$maxEE_rev),
    truncQ      = opt$truncQ,
    maxN        = opt$maxN,
    rm.phix     = opt$rmPhiX,
    maxLen      = opt$max_read_len,
    minLen      = opt$min_read_len,
    compress    = TRUE,
    verbose     = TRUE,
    multithread = opt$ncpus
)

colnames(out) <- c('input', 'filtered')
write.csv(out, paste0(opt$sample_id, ".trimmed.txt"))
