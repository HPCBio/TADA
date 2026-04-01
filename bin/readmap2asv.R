#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: readmap2asv.R <readmap.RDS>")

readmap <- readRDS(args[1])

# Generate ASV FASTA
asvs <- DNAStringSet(readmap$seq)
names(asvs) <- readmap$id
writeXStringSet(asvs, file = "asvs.fna")
