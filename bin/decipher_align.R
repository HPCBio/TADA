#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(DECIPHER))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--seqs", type = "character", help = "Input FASTA file of sequences to align"),
    make_option("--ncpus", type = "integer", default = 1, help = "Number of processors to use [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$seqs)) stop("--seqs is required")

seqs <- readDNAStringSet(opt$seqs)
alignment <- AlignSeqs(seqs, anchor = NA, processors = opt$ncpus)
writeXStringSet(alignment, "asvs.aligned.fna")
