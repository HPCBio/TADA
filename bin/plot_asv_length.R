#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ShortRead))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: plot_asv_length.R <seqtab.RDS> <asvs.fna>")

seqtab <- readRDS(args[1])
asvs <- readDNAStringSet(args[2])

asv_counts <- colSums(seqtab)

# TODO: we can scale these by counts as well
seqlens <- data.frame(seqs = names(asvs),
                      lengths = nchar(asvs),
                      counts = asv_counts[names(asvs)])

# simple distribution
gg <- ggplot(seqlens, aes(x = lengths)) +
    geom_density() +
    ggtitle("Sequence Length Distribution") +
    xlab("Length (nt)")

ggsave('asv-length-distribution.pdf', device = 'pdf', height = 3, width = 5, units = 'in')

# save the plot; we may want to make this dynamic (e.g. plotly)
saveRDS(gg, 'asv-length-distribution.RDS')
