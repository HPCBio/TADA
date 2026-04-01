#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--seqtab", type = "character", help = "Input sequence table RDS file"),
    make_option("--ncpus", type = "integer", default = 1, help = "Number of processors to use [default %default]"),
    make_option("--extra_opts", type = "character", default = "",
        help = "Additional arguments passed to removeBimeraDenovo() as a comma-separated key=value string")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$seqtab)) stop("--seqtab is required")

st.all <- readRDS(opt$seqtab)

# Build base argument list
base_args <- list(st.all, method = "consensus", multithread = opt$ncpus, verbose = TRUE)

# Merge any extra opts passed as a raw R argument string
if (nzchar(opt$extra_opts)) {
    extra <- eval(parse(text = paste0("list(", opt$extra_opts, ")")))
    base_args <- modifyList(base_args, extra)
}

seqtab <- do.call(removeBimeraDenovo, base_args)

saveRDS(seqtab, "seqtab.nonchim.RDS")

# read tracking
seqtab.nonchim <- rowSums(seqtab)
nms <- gsub('(.R1)?.trim.fastq.gz', '', names(seqtab.nonchim))
nms <- gsub(".dd$", "", nms)
seqtab.nonchim <- as_tibble_col(seqtab.nonchim, column_name = "dada2.nonchim") %>%
    mutate(SampleID = nms, .before = 1)
write_csv(seqtab.nonchim, "seqtab.nonchimera.csv")
