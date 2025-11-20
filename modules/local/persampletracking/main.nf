process PER_SAMPLE_TRACKING {
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(dds)
    val(stage)

    output:
    path("priors.${stage}.R1.fna"), optional: true, emit: for_priors
    path("priors.${stage}.R2.fna"), optional: true, emit: rev_priors
    path("all.dd.${stage}.*.RDS"), emit: inferred
    path("dada2.denoised.${stage}.*.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def dadaOpt = params.dada_opts ? "${params.dada_opts}" : "NA"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))
    suppressPackageStartupMessages(library(openssl))
    suppressPackageStartupMessages(library(tidyverse))

    dadaOpt <- "${dadaOpt}"

    if (!is.na(dadaOpt)) {
      setDadaOpt(${dadaOpt})
      cat("dada Options:\\n",${dadaOpt},"\\n")
    }

    dadaopts <- getDadaOpt()

    getN <- function(x) sum(getUniques(x))

    dadaFs <- lapply(list.files(path = '.', pattern = '.dd.${stage}.R1.RDS'), function (x) readRDS(x))
    dadaRs <- lapply(list.files(path = '.', pattern = '.dd.${stage}.R2.RDS'), function (x) readRDS(x))
    names(dadaFs) <- sub('.dd.${stage}.R1.RDS', '', list.files('.', pattern = '.dd.${stage}.R1.RDS'))
    saveRDS(dadaFs, "all.dd.${stage}.R1.RDS")

    tracking_ddFs <- as.data.frame(sapply(dadaFs, getN)) 
    colnames(tracking_ddFs) <- c("dada2.denoised.${stage}.R1")  
    tracking_ddFs <- tracking_ddFs %>%
        as_tibble() %>%
        mutate(SampleID = rownames(tracking_ddFs), .before = 1)
    write_csv(tracking_ddFs, "dada2.denoised.${stage}.R1.csv")

    # we want to standardize these for later changes, so let's generate a 
    # simple FASTA file of the priors, using dada2 opts
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

    priorsF <- generate_priors(dadaFs, idtype="${params.id_type}")
    if (is.na(priorsF)) {
        message("No priors found for R1!")
    } else {
        writeFasta(priorsF, file = 'priors.${stage}.R1.fna')
    }
    if (length(dadaRs) > 0) {
        names(dadaRs) <- sub('.dd.${stage}.R2.RDS', '', list.files('.', pattern = '.dd.${stage}.R2.RDS'))
        saveRDS(dadaRs, "all.dd.${stage}.R2.RDS")

        tracking_ddRs <- as.data.frame(sapply(dadaRs, getN))
        colnames(tracking_ddRs) <- c("dada2.denoised.${stage}.R2")
        tracking_ddRs <- tracking_ddRs %>%
            as_tibble() %>%
            mutate(SampleID = rownames(tracking_ddRs), .before = 1)
        write_csv(tracking_ddRs, "dada2.denoised.${stage}.R2.csv")

        priorsR <- generate_priors(dadaRs, idtype="${params.id_type}")
        if (is.na(priorsR)) {
            message("No priors found for R2!")
        } else {
            writeFasta(priorsR, file = "priors.${stage}.R2.fna")
        }
    }
    if (!file.exists("priors.${stage}.R1.fna")) {
        file.create("priors.${stage}.R1.fna")
    }
    if (!file.exists("priors.${stage}.R2.fna")) {
        file.create("priors.${stage}.R2.fna")
    }
    """
}
