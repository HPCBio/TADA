#!/usr/bin/env Rscript

# Main purpose of this script is to merge all trimming data into one table
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--trimmer", type = "character", default = "dada2",
        help = "Trimmer used: 'dada2' or 'cutadapt' [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (opt$trimmer == "dada2") {
    trimmedFiles <- list.files(path = '.', pattern = '*.trimmed.txt')
    sample.names <- sub('.trimmed.txt', '', trimmedFiles)
    # TODO: switch to dplyr bind_rows
    trimmed <- do.call("rbind", lapply(trimmedFiles, function(x) as.data.frame(read.csv(x))))
    colnames(trimmed) <- c("dada2.ft.sequence", "dada2.ft.input", "dada2.ft.filtered")
    trimmed$SampleID <- sample.names
    write.csv(trimmed, "all.trimmed.csv", row.names = FALSE)
} else { # has to be cutadapt
    read_cutadapt <- function(x) {
        counts <- read_tsv(x, col_names = TRUE, show_col_types = FALSE)
        counts
    }

    # gather files and load
    cutadapt_files <- list.files(path = ".", pattern = "*.cutadapt.log")
    cutadapt_sample_data <- lapply(cutadapt_files, read_cutadapt)

    # fix sample names
    nms <- gsub(".cutadapt.log", "", cutadapt_files)
    names(cutadapt_sample_data) <- nms

    # only keep some data
    to_keep <- c("SampleID", "status", "in_reads", "too_short",
        "too_long", "too_many_n", "out_reads", "w/adapters")
    if ("w/adapters2" %in% colnames(cutadapt_sample_data[[1]])) {
        to_keep <- c(to_keep, "w/adapters2")
    }
    final_cutadapt <- bind_rows(cutadapt_sample_data, .id = "SampleID") %>%
        select(all_of(to_keep))
    # keep sampleID intact, but prepend 'cutadapt' to other columns
    colnames(final_cutadapt)[2:length(to_keep)] <- paste0("cutadapt.", colnames(final_cutadapt)[2:length(to_keep)])
    write.csv(final_cutadapt, "all.trimmed.csv", row.names = FALSE)
}
