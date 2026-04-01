#!/usr/bin/env Rscript
suppressPackageStartupMessages({
    library(dada2)
    library(optparse)
})

option_list <- list(
    make_option("--readmode", type = "character", help = "Read mode label (e.g. R1, R2)"),
    make_option("--errfunc", type = "character", default = "loessErrfun",
        help = "Error estimation function name or 'custom' [default %default]"),
    make_option("--custom_code", type = "character", default = "",
        help = "Path to R file defining customErrfun (used when --errfunc custom)"),
    make_option("--quality_bins", type = "character", default = "",
        help = "Comma-separated quality bin values for makeBinnedQualErrfun()"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a key=value string passed to setDadaOpt()"),
    make_option("--learnerrors_opts", type = "character", default = "",
        help = "Additional arguments passed to learnErrors() as a key=value string"),
    make_option("--quality_binning", type = "logical", default = FALSE,
        help = "Apply legacy quality score binning correction [default %default]"),
    make_option("--random_seed", type = "integer", default = 100,
        help = "Random seed [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$readmode)) stop("--readmode is required")

errFunc <- NA

if (opt$errfunc == "custom") {
    source(opt$custom_code)
    errFunc <- customErrfun
} else if (opt$errfunc == "makeBinnedQualErrfun") {
    bins <- as.integer(strsplit(opt$quality_bins, ",")[[1]])
    errFunc <- makeBinnedQualErrfun(bins)
} else {
    errFunc <- get(opt$errfunc)
}

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

# File parsing
filts <- list.files('.', pattern = ".trim.fastq.gz", full.names = TRUE)

set.seed(opt$random_seed)

# Build learnErrors call args
learn_args <- list(
    filts,
    multithread = opt$ncpus,
    errorEstimationFunction = errFunc,
    verbose = TRUE
)

if (nzchar(opt$learnerrors_opts)) {
    extra <- eval(parse(text = paste0("list(", opt$learnerrors_opts, ")")))
    learn_args <- modifyList(learn_args, extra)
}

# Learn read error rates
err <- do.call(learnErrors, learn_args)

# Legacy binning correction (deprecated in favor of using a binned error function)
if (isTRUE(opt$quality_binning)) {
    print("Running binning correction")
    errs <- t(apply(getErrors(err), 1, function(x) { x[x < x[40]] <- x[40]; return(x) }))
    err$err_out <- errs
}

pdf(paste0(opt$readmode, ".", opt$errfunc, ".err.pdf"))
plotErrors(err, nominalQ = TRUE)
dev.off()

saveRDS(err, paste0("errors.", opt$readmode, ".RDS"))
