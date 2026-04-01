#!/usr/bin/env Rscript

# Main purpose of this script is to merge all cutadapt trimming data into one table
suppressPackageStartupMessages(library(tidyverse))

read_cutadapt <- function(x) {
    counts <- read_tsv(x, col_names = TRUE, show_col_types = FALSE)
    counts
}

# gather files and load
cutadapt_files <- list.files(path = ".", pattern = "*.cutadapt.out")
cutadapt_sample_data <- lapply(cutadapt_files, read_cutadapt)

# fix sample names
nms <- gsub(".cutadapt.out", "", cutadapt_files)
names(cutadapt_sample_data) <- nms

# only keep some data
to_keep <- c("SampleID", "status", "in_reads", "too_short",
    "too_long", "too_many_n", "out_reads", "w/adapters", "w/adapters2")
final_cutadapt <- bind_rows(cutadapt_sample_data, .id = "SampleID") %>%
    select(all_of(to_keep))
# keep sampleID intact, but prepend 'cutadapt' to other columns
colnames(final_cutadapt)[2:length(to_keep)] <- paste0("cutadapt.", colnames(final_cutadapt)[2:length(to_keep)])
write.csv(final_cutadapt, "all.trimmed.csv", row.names = FALSE)
