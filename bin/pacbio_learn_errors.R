#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--readmode", type = "character", help = "Read mode label (e.g. R1)"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a comma-separated key=value string passed to setDadaOpt()"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$readmode)) stop("--readmode is required")

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

# File parsing
filts <- list.files('.', pattern = "filtered.fastq.gz", full.names = TRUE)
sample.namesF <- sapply(strsplit(basename(filts), "_"), `[`, 1) # Assumes filename = samplename_XXX.fastq.gz
set.seed(100)

dereps <- derepFastq(filts, n = 100000, verbose = TRUE)

# Learn forward error rates
errs <- learnErrors(dereps,
    nbases = 1e8,
    errorEstimationFunction = PacBioErrfun,
    BAND_SIZE = 32,
    multithread = opt$ncpus,
    verbose = TRUE)

pdf(paste0(opt$readmode, ".err.pdf"))
plotErrors(errs, nominalQ = TRUE)
dev.off()

saveRDS(errs, paste0("errors.", opt$readmode, ".RDS"))
