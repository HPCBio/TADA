#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: taxtable2txt.R <taxtab.RDS> <metrics.RDS>")

tax <- readRDS(args[1])

# Generate table output
write.table(data.frame('ASVID' = row.names(tax), tax),
    file = 'taxtab.txt',
    row.names = FALSE,
    col.names = c('#OTU ID', colnames(tax)), sep = "\t")

write.table(data.frame('ASVID' = row.names(tax), tax),
    file = 'taxtab.full.txt',
    row.names = FALSE,
    col.names = c('#OTU ID', colnames(tax)), sep = "\t")

if (file.exists(args[2])) {
    boots <- readRDS(args[2])
    write.table(data.frame('ASVID' = row.names(boots), boots),
        file = 'metrics.txt',
        row.names = FALSE,
        col.names = c('#OTU ID', colnames(boots)), sep = "\t")
    saveRDS(boots, "taxmetrics.RDS")
}

# Write modified data
saveRDS(tax, "taxtab.RDS")
