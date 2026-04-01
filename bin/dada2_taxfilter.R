#!/usr/bin/env Rscript

# TODO: quick hack script, could be cleaned up
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--readmap", type = "character", help = "Input readmap RDS file"),
    make_option("--seqtab", type = "character", help = "Input sequence table RDS file"),
    make_option("--taxtab", type = "character", help = "Input taxonomy table RDS file"),
    make_option("--metrics", type = "character", help = "Input taxonomy metrics RDS file"),
    make_option("--tax_filter_rank", type = "character", help = "Taxonomic rank column to filter on (must be non-NA)")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("readmap", "seqtab", "taxtab", "metrics", "tax_filter_rank")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

taxtab <- readRDS(opt$taxtab)
taxtab_filtered <- taxtab %>%
    as_tibble(rownames = "TaxID") %>%
    filter(!is.na(.data[[opt$tax_filter_rank]]))
ids <- taxtab_filtered$TaxID

readmap <- readRDS(opt$readmap)
readmap_filtered <- readmap[readmap$id %in% ids, ]

seqtab <- readRDS(opt$seqtab)
seqtab_filtered <- seqtab[, ids]

# read tracking
seqtab.taxfilter <- rowSums(seqtab_filtered)
nms <- names(seqtab.taxfilter)
seqtab.taxfilter <- as_tibble_col(seqtab.taxfilter, column_name = "dada2.taxfilter") %>%
    mutate(SampleID = nms, .before = 1)
write_csv(seqtab.taxfilter, "taxfiltered.summary.csv")

metrics <- readRDS(opt$metrics)
metrics_filtered <- metrics[ids, ]

asvs_filtered <- DNAStringSet(readmap_filtered$seq)
names(asvs_filtered) <- readmap_filtered$id

taxtab_filtered <- taxtab_filtered %>%
    column_to_rownames(var = "TaxID") %>%
    as.matrix()

writeXStringSet(asvs_filtered, file = "asvs.tax_filtered.fna")
# Write modified data
saveRDS(seqtab_filtered, "seqtab.tax_filtered.RDS")
saveRDS(taxtab_filtered, "taxtab.tax_filtered.RDS")
saveRDS(metrics_filtered, "taxmetrics.tax_filtered.RDS")
saveRDS(readmap_filtered, "readmap.tax_filtered.RDS")
