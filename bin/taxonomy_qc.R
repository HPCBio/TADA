#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: taxonomy_qc.R <taxtab.RDS>")

# TODO: add option to switch ranks
ranks <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

taxa <- readRDS(args[1])

freqs <- taxa %>%
    mutate(across(ranks, ~
                    as.factor(
                        case_when(
                            is.na(.) ~ "Unassigned",
                            str_detect(., "__$") ~ "Unclassified",
                            TRUE ~ "Classified"
                        )))) %>%
    pivot_longer(!`Feature ID`, names_to = "Rank", values_to = "Status") %>%
    mutate(Rank = factor(Rank, levels = ranks)) %>%
    group_by(Rank) %>%
    count(Status)

bp <- ggplot(freqs, aes(x = Rank, y = n, fill = Status)) +
    geom_bar(stat = "identity", position = "stack")

ggsave("assigned_taxonomy.pdf", bp)
