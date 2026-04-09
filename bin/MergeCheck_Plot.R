#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

# A very simple plot script for generating a 'heatmap' checking overlaps.
option_list = list(
  make_option("--forward",
    type    = "character",
    default = "",
    help    = "Forward (5') primer"),
  make_option("--reverse", 
    type    = "character",
    default = "",
    help    = "Reverse (5') primer")
)

opt <- parse_args(OptionParser(option_list = option_list))

len_files <- list.files(".",
                        pattern    = "*.lengthstats.txt",
                        full.names = TRUE)

lens_tmp <- lapply(len_files,
                   read_tsv,
                   col_names = c("Length", "Count"), col_types = "ii")

names(lens_tmp) <- gsub("\\S+/(\\S+).lengthstats.txt", "\\1", len_files)

# bind all the data,
# group by Sample,
# add in relative abundance per Sample and binning info,
# group by Sample + Bin,
# summarize counts and RelAb per bin.
lens_all <- bind_rows(lens_tmp, .id = "Sample") |>
  group_by(Sample) |>
  mutate(RelAb = Count / sum(Count),
         Bin   = cut(Length,
                     seq(min(Length),
                         max(Length), 5),
                     include.lowest = TRUE)) |>
  group_by(Sample, Bin) |>
  mutate(ReadCountPerBin = sum(Count),
         RelAbPerBin     = sum(RelAb))

lens_all$Sample <- factor(lens_all$Sample)

# This will become settable, but essentially anything 50nt or less is not kept
cutoff <- nchar(opt$forward) + nchar(opt$reverse)

if (cutoff == 0) {
  cutoff <- 50
}

cat("Cutoff is ", cutoff)

gg <- lens_all |>
  ggplot(aes(x = Length, y = Sample, fill = ReadCountPerBin)) +
  geom_tile(stat = "identity") +
  scale_fill_viridis_c(option = "plasma", direction = -1) +
  annotate("rect",
           xmin  = 0,
           xmax  = cutoff,
           ymin  = 0.5,
           ymax  = Inf,
           alpha = 0.1,
           fill  = "blue") +
  theme_minimal()

if (nlevels(lens_all$Sample) > 50) {
  gg <- gg + theme(axis.text.y = element_blank())
}

ggsave("MergedCheck_heatmap.counts.pdf", gg)

gg2 <- lens_all |>
  ggplot(aes(x = Length, y = Sample, fill = RelAbPerBin)) +
  geom_tile(stat = "identity") +
  scale_fill_viridis_c(option = "plasma", direction = -1) +
  annotate("rect",
           xmin  = 0,
           xmax  = cutoff,
           ymin  = 0.5,
           ymax  = Inf,
           alpha = 0.1,
           fill  = "blue") +
  theme_minimal()

if (nlevels(lens_all$Sample) > 50) {
  gg2 <- gg2 + theme(axis.text.y = element_blank())
}

ggsave("MergedCheck_heatmap.RelAb.pdf", gg2)

saveRDS(lens_all, "stats.RDS")
