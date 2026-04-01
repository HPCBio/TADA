#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: seqtable2txt.R <seqtab.RDS>")

seqtab <- readRDS(args[1])

# Generate table output
write.table(data.frame('SampleID' = row.names(seqtab), seqtab),
    file = 'seqtab.txt',
    row.names = FALSE,
    col.names = c('#SampleID', colnames(seqtab)), sep = "\t")

# Generate OTU table for QIIME2 import (rows = ASVs, cols = samples)
write.table(
    data.frame('Taxa' = colnames(seqtab), t(seqtab), check.names = FALSE),
    file = 'seqtab.qiime2.txt',
    row.names = FALSE,
    quote = FALSE,
    sep = "\t")

# Write modified data
saveRDS(seqtab, "seqtab.RDS")
