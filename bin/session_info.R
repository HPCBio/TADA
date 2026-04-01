#!/usr/bin/env Rscript
pkgs <- c(
    "RCurl",
    "tidyverse",
    "pander",
    "phangorn",
    "dplyr",
    "dada2",
    "DECIPHER",
    "digest",
    "biomformat",
    "optparse"
)
lapply(pkgs, require, character.only = TRUE)

sink('sessionInfo.Rmd')
rmd <- pander(sessionInfo(), compact = FALSE)
sink()
