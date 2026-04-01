#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: qiime2_feature_to_rds.R <taxonomy.tsv>")

# TODO: add option to switch ranks
ranks <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

# this splits the ranks into separate columns
qiime2 <- read_tsv(args[1]) %>%
    rename(TaxID = "Feature ID") %>%
    separate(Taxon, sep = ";", into = ranks, fill = "right")

taxa <- qiime2 %>%
    select(-c(Confidence, TaxID)) %>%
    as.data.frame()

rownames(taxa) <- qiime2$TaxID

saveRDS(taxa, "taxtab.qiime2.RDS")
saveRDS(qiime2, "confidence.qiime2.RDS")
