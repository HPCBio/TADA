#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--readmode", type = "character", help = "Read mode label (e.g. R1, merged)"),
    make_option("--stage", type = "character", help = "Stage label used in input/output filenames"),
    make_option("--min_asv_len", type = "integer", default = 0,
        help = "Minimum ASV length filter (0 = no filter) [default %default]"),
    make_option("--max_asv_len", type = "integer", default = 0,
        help = "Maximum ASV length filter (0 = no filter) [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("readmode", "stage")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

# important point; this instance covers both single-end
# and merged data. *Only merged data goes on to read tracking*
combineFiles <- list.files(path = '.', pattern = paste0('.', opt$stage, '.', opt$readmode, '.RDS$'))
pairIds <- sub(paste0('.', opt$stage, '.', opt$readmode, '.RDS'), '', combineFiles)
combined <- lapply(combineFiles, function(x) readRDS(x))
names(combined) <- pairIds
seqtab <- makeSequenceTable(combined)
saveRDS(seqtab, paste0("seqtab.original.", opt$stage, ".", opt$readmode, ".RDS"))

seqtab_stats <- rowSums(seqtab)
nms <- gsub(".dd", "", names(seqtab_stats))
seqtab_stats <- as_tibble_col(seqtab_stats, column_name = paste0("dada.", opt$stage, ".seqtab.raw")) %>%
    mutate(SampleID = nms, .before = 1)

write_csv(seqtab_stats, paste0("seqtab.original.", opt$stage, ".", opt$readmode, ".csv"))

# this is an optional filtering step to remove *merged* sequences based on
# min/max length criteria
if (opt$min_asv_len > 0) {
    seqtab <- seqtab[, nchar(colnames(seqtab)) >= opt$min_asv_len, drop = FALSE]
}

if (opt$max_asv_len > 0) {
    seqtab <- seqtab[, nchar(colnames(seqtab)) <= opt$max_asv_len, drop = FALSE]
}

saveRDS(seqtab, paste0("seqtab.", opt$stage, ".", opt$readmode, ".RDS"))

if (opt$min_asv_len > 0 | opt$max_asv_len > 0) {
    seqtab_stats <- rowSums(seqtab)
    nms <- gsub(".dd", "", names(seqtab_stats))
    seqtab_stats <- as_tibble_col(seqtab_stats, column_name = paste0("dada.", opt$stage, ".seqtab.lengthfiltered")) %>%
        mutate(SampleID = nms, .before = 1)
    write_csv(seqtab_stats, paste0("seqtab.", opt$stage, ".", opt$readmode, ".lengthfiltered.csv"))
}

if (opt$readmode == "merged") {
    mergers <- as.data.frame(sapply(combined, function(x) sum(getUniques(x %>% filter(accept)))))
    colnames(mergers) <- c(paste0("dada2.", opt$stage, ".merged"))
    mergers <- mergers %>%
        as_tibble() %>%
        mutate(SampleID = rownames(mergers), .before = 1)
    write_csv(as_tibble(mergers), paste0("all_merged.", opt$stage, ".csv"))
    saveRDS(combined, paste0("all.", opt$stage, ".merged.RDS"))
}
