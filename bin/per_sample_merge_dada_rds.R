#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(openssl))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--stage", type = "character", help = "Stage label used in input/output filenames"),
    make_option("--id_type", type = "character", default = "md5",
        help = "ASV ID type for priors: 'md5' or 'simple' [default %default]"),
    make_option("--dada_opts", type = "character", default = "",
        help = "Additional dada options as a key=value string passed to setDadaOpt()")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$stage)) stop("--stage is required")

if (nzchar(opt$dada_opts)) {
    eval(parse(text = paste0("setDadaOpt(", opt$dada_opts, ")")))
    cat("dada Options:\n", opt$dada_opts, "\n")
}

dadaopts <- getDadaOpt()

# we want to standardize these for later changes, so let's generate a
# simple FASTA file of the priors
generate_priors <- function(x, opts = dadaopts, idtype = "md5") {
    st <- makeSequenceTable(x)
    # Moving to using the pseudo priors code from Ben here:
    # https://github.com/benjjneb/dada2/blame/278f5f3ec03a846fe157b283cc08f2dd30430ae0/R/dada.R#L400
    pseudo_priors <- colnames(st)[colSums(st > 0) >= opts$PSEUDO_PREVALENCE | colSums(st) >= opts$PSEUDO_ABUNDANCE]
    if (length(pseudo_priors) > 0) {
        ids <- switch(idtype,
            simple = paste("priorF_", 1:length(pseudo_priors), sep = ""),
            md5 = md5(pseudo_priors))
        seqs.dna <- ShortRead(sread = DNAStringSet(pseudo_priors), id = BStringSet(ids))
        return(seqs.dna)
    } else {
        return(NA)
    }
}

dadaFs <- lapply(list.files(path = '.', pattern = paste0('.dd.', opt$stage, '.R1.RDS')), function(x) readRDS(x))
dadaRs <- lapply(list.files(path = '.', pattern = paste0('.dd.', opt$stage, '.R2.RDS')), function(x) readRDS(x))
names(dadaFs) <- sub(paste0('.dd.', opt$stage, '.R1.RDS'), '', list.files('.', pattern = paste0('.dd.', opt$stage, '.R1.RDS')))
saveRDS(dadaFs, paste0("all.dd.", opt$stage, ".R1.RDS"))

priorsF <- generate_priors(dadaFs, idtype = opt$id_type)
if (is.na(priorsF)) {
    message("No priors found for R1!")
} else {
    writeFasta(priorsF, file = paste0('priors.', opt$stage, '.R1.fna'))
}
if (length(dadaRs) > 0) {
    names(dadaRs) <- sub(paste0('.dd.', opt$stage, '.R2.RDS'), '', list.files('.', pattern = paste0('.dd.', opt$stage, '.R2.RDS')))
    saveRDS(dadaRs, paste0("all.dd.", opt$stage, ".R2.RDS"))
    priorsR <- generate_priors(dadaRs, idtype = opt$id_type)
    if (is.na(priorsR)) {
        message("No priors found for R2!")
    } else {
        writeFasta(priorsR, file = paste0("priors.", opt$stage, ".R2.fna"))
    }
}
# create a stub empty file, which should be caught and skipped on
# next round (needed for SE data)
if (!file.exists(paste0("priors.", opt$stage, ".R2.fna"))) {
    file.create(paste0("priors.", opt$stage, ".R2.fna"))
}
