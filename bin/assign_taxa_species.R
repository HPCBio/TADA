#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--seqtab", type = "character", help = "Input readmap RDS (with id and seq columns)"),
    make_option("--ref", type = "character", help = "Reference FASTA for assignTaxonomy"),
    make_option("--species_ref", type = "character", default = "null",
        help = "Reference FASTA for addSpecies(); omit or 'null' to skip species assignment"),
    make_option("--tax_batch", type = "integer", default = 0,
        help = "Batch size for taxonomy assignment (0 = no batching) [default %default]"),
    make_option("--min_boot", type = "integer", default = 50,
        help = "Minimum bootstrap confidence for taxonomy assignment [default %default]"),
    make_option("--ncpus", type = "integer", default = 1,
        help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
for (arg in c("seqtab", "ref")) {
    if (is.null(opt[[arg]])) stop(paste("--", arg, " is required", sep = ""))
}

runSpecies <- !is.null(opt$species_ref) && opt$species_ref != "null"

seqs <- readRDS(opt$seqtab)
seqtab <- seqs$seq

# Assign taxonomy
tax <- NULL
boots <- NULL

if (opt$tax_batch == 0 | length(seqtab) < opt$tax_batch) { # no batch, run normally
    cat("Running all samples\n")
    tax <- assignTaxonomy(seqtab, opt$ref,
        multithread = opt$ncpus,
        tryRC = TRUE,
        outputBootstraps = TRUE,
        minBoot = opt$min_boot,
        verbose = TRUE)
    boots <- tax$boot
    if (runSpecies) {
        tax <- addSpecies(tax$tax, opt$species_ref, tryRC = TRUE, verbose = TRUE)
    } else {
        tax <- tax$tax
    }
} else {
    # see https://github.com/benjjneb/dada2/issues/1429 for this
    to_split <- seq(1, length(seqtab), by = opt$tax_batch)
    to_split2 <- c(to_split[2:length(to_split)] - 1, length(seqtab))

    for (i in 1:length(to_split)) {
        cat(paste("Running all samples from", to_split[i], "to", to_split2[i], "\n"))
        seqtab2 <- seqtab[to_split[i]:to_split2[i]]
        tax2 <- assignTaxonomy(seqtab2, opt$ref,
            multithread = opt$ncpus,
            tryRC = TRUE,
            outputBootstraps = TRUE,
            minBoot = opt$min_boot,
            verbose = TRUE)

        if (is.null(boots)) {
            boots <- tax2$boot
        } else {
            boots <- rbind(boots, tax2$boot)
        }

        if (runSpecies) {
            tax2 <- addSpecies(tax2$tax,
                refFasta = opt$species_ref,
                tryRC = TRUE,
                verbose = TRUE)
        } else {
            tax2 <- tax2$tax
        }
        if (is.null(tax)) {
            tax <- tax2
        } else {
            tax <- rbind(tax, tax2)
        }
    }
}

# make sure these are the same order
rownames(tax) <- seqs[rownames(tax), ]$id
rownames(boots) <- seqs[rownames(boots), ]$id

# Write original data
saveRDS(tax, "taxtab.original.RDS")
saveRDS(boots, "bootstraps.original.RDS")
