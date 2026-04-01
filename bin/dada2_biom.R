#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(biomformat))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: dada2_biom.R <seqtab.RDS> <taxtab.RDS>")

seqtab <- readRDS(args[1])
taxtab <- readRDS(args[2])
packageVersion("biomformat")
st.biom <- make_biom(t(seqtab), observation_metadata = taxtab)
write_biom(st.biom, "final.biom")
