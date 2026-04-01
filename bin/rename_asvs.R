#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(ShortRead))
suppressPackageStartupMessages(library(digest))
suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option("--seqtab", type = "character", help = "Non-chimeric sequence table RDS"),
    make_option("--raw_seqtab", type = "character", help = "Raw (pre-chimera-removal) sequence table RDS"),
    make_option("--id_type", type = "character", default = "md5",
        help = "ASV ID type: 'md5' or 'simple' [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (is.null(opt$seqtab) || is.null(opt$raw_seqtab)) stop("--seqtab and --raw_seqtab are required")

# read RDS w/ data
st <- readRDS(opt$seqtab)
st.raw <- readRDS(opt$raw_seqtab)

# get sequences
seqs <- colnames(st)
seqs.raw <- colnames(st.raw)

# get IDs based on idType
ids_study <- switch(opt$id_type,
    simple = paste("ASV", 1:ncol(st), sep = ""),
    md5 = sapply(colnames(st), digest, algo = "md5"))
ids_study.raw <- switch(opt$id_type,
    simple = paste("ASV", 1:ncol(st.raw), sep = ""),
    md5 = sapply(colnames(st.raw), digest, algo = "md5"))

# sub IDs
colnames(st) <- unname(ids_study)
colnames(st.raw) <- unname(ids_study.raw)

# generate FASTA
seqs.dna <- ShortRead(sread = DNAStringSet(seqs), id = BStringSet(ids_study))
writeFasta(seqs.dna, file = paste0('asvs.', opt$id_type, '.nochim.fna'))

seqs.dna.raw <- ShortRead(sread = DNAStringSet(seqs.raw), id = BStringSet(ids_study.raw))
writeFasta(seqs.dna.raw, file = paste0('asvs.', opt$id_type, '.raw.fna'))

# replace rownames
rownames(st) <- gsub("(.R1)?.trim.fastq.gz", "", rownames(st))
rownames(st) <- gsub(".dd$", "", rownames(st))
rownames(st.raw) <- gsub("(.R1)?.trim.fastq.gz", "", rownames(st.raw))
rownames(st.raw) <- gsub(".dd$", "", rownames(st.raw))

# Write modified data (note we only keep the no-chimera reads for the next stage)
saveRDS(st, paste0("seqtab.", opt$id_type, ".RDS"))
saveRDS(data.frame(id = ids_study, seq = seqs), "readmap.RDS")
