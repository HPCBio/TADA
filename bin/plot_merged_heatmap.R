#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--mergers", type = "character", help = "Input mergers RDS file"),
    make_option("--min_asv_len", type = "integer", default = 0,
        help = "Minimum ASV length; adds dashed blue vline if > 0 [default %default]"),
    make_option("--max_asv_len", type = "integer", default = 0,
        help = "Maximum ASV length; adds dashed red vline if > 0 [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$mergers)) stop("--mergers is required")

mergers <- readRDS(opt$mergers)

# filter out any samples w/o reads (nrows == 0)
all_mergers <- mergers %>% discard(\(x) nrow(x) == 0) %>% bind_rows(.id = 'SampleID')

all_mergers$SampleID <- factor(gsub(".R1.filtered.fastq.gz", "", all_mergers$SampleID))

# we only keep those that pass here (accept == TRUE)
gg <- all_mergers %>%
    filter(accept) %>%
    ggplot(aes(x = nmatch, y = SampleID)) +
    stat_bin2d(binwidth = c(2, 1), aes(fill = after_stat(ncount))) +
    scale_fill_viridis_c() +
    theme_minimal()

if (nlevels(all_mergers$SampleID) > 40) {
    gg <- gg + theme(axis.text.y = element_blank())
}

if (opt$min_asv_len > 0) {
    gg <- gg + geom_vline(xintercept = opt$min_asv_len, linetype = "dashed", color = "blue")
}

if (opt$max_asv_len > 0) {
    gg <- gg + geom_vline(xintercept = opt$max_asv_len, linetype = "dashed", color = "red")
}

img_height <- ifelse(nlevels(all_mergers$SampleID) <= 50, 0.09 * nlevels(all_mergers$SampleID), 9)

ggsave('read-overlap-heatmap.pdf',
    plot = gg, device = 'pdf', width = 7, height = img_height, units = 'in')

# save the plot; we may want to make this dynamic (e.g. plotly)
saveRDS(gg, 'read-overlap-heatmap.RDS')
