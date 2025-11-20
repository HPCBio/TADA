// TODO: this module needs to be renamed, the current name is 
// not technically correct and confusing with other outputs
// The main purposes are two-fold: 
// 1) combine the two denoised outputs for read tracking, and 
// 2) to generate prior R1 and R2 (if present) sequences for later

process PER_SAMPLE_MERGE {
    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(dds)
    val(stage)

    output:
    path("all.dd.${stage}.*.RDS"), emit: inferred // to readtracking
    path("priors.${stage}.R1.fna"), optional: true, emit: priors_for
    path("priors.${stage}.R2.fna"), optional: true, emit: priors_rev

    when:
    task.ext.when == null || task.ext.when

    script:
    def dadaOpt = params.dada_opts ? "${params.dada_opts}" : "NA"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))
    suppressPackageStartupMessages(library(openssl))

    dadaOpt <- "${dadaOpt}"

    if (!is.na(dadaOpt)) {
      setDadaOpt(${dadaOpt})
      cat("dada Options:\\n",${dadaOpt},"\\n")
    }

    dadaopts <- getDadaOpt()

    # we want to standardize these for later changes, so let's generate a 
    # simple FASTA file of the priors, using 
    generate_priors <- function(x, opts = dadaopts, idtype="md5") {
        st <- makeSequenceTable(x)
        # Moving to using the pseudo priors code from Ben here:
        # https://github.com/benjjneb/dada2/blame/278f5f3ec03a846fe157b283cc08f2dd30430ae0/R/dada.R#L400
        pseudo_priors <- colnames(st)[colSums(st>0) >= opts\$PSEUDO_PREVALENCE | colSums(st) >= opts\$PSEUDO_ABUNDANCE]
        if (length(pseudo_priors) > 0) {
            ids <- switch(idtype, simple=paste("priorF_", 1:length(pseudo_priors), sep = ""),
                                    md5=md5(pseudo_priors))
            seqs.dna <- ShortRead(sread = DNAStringSet(pseudo_priors), id = BStringSet(ids))
            return(seqs.dna)
        } else {
            return(NA)
        }
    }

    # this is necessary for QC, but we also want to do this if we want priors from the run
    dadaFs <- lapply(list.files(path = '.', pattern = '.dd.${stage}.R1.RDS'), function (x) readRDS(x))
    dadaRs <- lapply(list.files(path = '.', pattern = '.dd.${stage}.R2.RDS'), function (x) readRDS(x))
    names(dadaFs) <- sub('.dd.${stage}.R1.RDS', '', list.files('.', pattern = '.dd.${stage}.R1.RDS'))
    saveRDS(dadaFs, "all.dd.${stage}.R1.RDS")

    priorsF <- generate_priors(dadaFs, idtype="${params.id_type}")
    if (is.na(priorsF)) {
        message("No priors found for R1!")
        # TODO: prior versions of this module made empty FASTA files if no 
        # priors were found, but this should technically be a warning flag!
    } else {
        writeFasta(priorsF, file = 'priors.${stage}.R1.fna')
    }
    if (length(dadaRs) > 0) {
        names(dadaRs) <- sub('.dd.${stage}.R2.RDS', '', list.files('.', pattern = '.dd.${stage}.R2.RDS'))
        saveRDS(dadaRs, "all.dd.${stage}.R2.RDS")
        priorsR <- generate_priors(dadaRs, idtype="${params.id_type}")
        if (is.na(priorsR)) {
            message("No priors found for R2!")
        } else {
            writeFasta(priorsR, file = "priors.${stage}.R2.fna")
        }
    }
    # create a stub empty file, which should be caught and skipped on 
    # next round (needed for SE data)
    if (!file.exists("priors.${stage}.R2.fna")) {
        file.create("priors.${stage}.R2.fna")
    }
    """
}