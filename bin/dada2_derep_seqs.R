#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--fwd", type = "character", help = "Forward (R1) filtered FASTQ file"),
    make_option("--rev", type = "character", default = "null",
        help = "Reverse (R2) filtered FASTQ file; omit or pass 'null' for single-end"),
    make_option("--sample_id", type = "character", help = "Sample ID used for output file naming"),
    make_option("--maxrecords", type = "integer", default = 100000,
        help = "Max records to read per derep call [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("fwd", "sample_id")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

derepsF <- derepFastq(opt$fwd, n = opt$maxrecords, verbose = TRUE)
derepsF$file <- basename(opt$fwd)
saveRDS(derepsF, paste0(opt$sample_id, ".R1.derep.RDS"))

if (!is.null(opt$rev) && opt$rev != "null") {
    derepsR <- derepFastq(opt$rev, n = opt$maxrecords, verbose = TRUE)
    derepsR$file <- basename(opt$rev)
    saveRDS(derepsR, paste0(opt$sample_id, ".R2.derep.RDS"))
}
