#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--readmode", type = "character", help = "Read mode label (e.g. R1, R2)"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a comma-separated key=value string passed to setDadaOpt()"),
    make_option("--quality_binning", type = "logical", default = FALSE,
        help = "Apply quality score binning correction (e.g. for NovaSeq) [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$readmode)) stop("--readmode is required")

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

# File parsing (these come from the process input channel)
filts <- list.files('.', pattern = paste0(opt$readmode, ".filtered.fastq.gz"), full.names = TRUE)
sample.names <- sapply(strsplit(basename(filts), "_"), `[`, 1) # Assumes filename = samplename_XXX.fastq.gz
set.seed(100)

dereps <- derepFastq(filts, n = 100000, verbose = TRUE)

# Learn forward error rates
err <- learnErrors(dereps, multithread = opt$ncpus, verbose = 1)

# This is a rough correction for NovaSeq binning issues
# See https://github.com/h3abionet/TADA/issues/31
if (isTRUE(opt$quality_binning)) {
    # TODO: add alternatives for binning
    print("Running binning correction")
    errs <- t(apply(getErrors(err), 1, function(x) { x[x < x[40]] <- x[40]; return(x) }))
    err$err_out <- errs
}

pdf(paste0(opt$readmode, ".err.pdf"))
plotErrors(err, nominalQ = TRUE)
dev.off()

saveRDS(err, paste0("errors.", opt$readmode, ".RDS"))
