process DADA2_POOLED_INFER {
    tag "${readmode}: ${params.pool}"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), path(err), path(filts)

    

    output:
    tuple val(readmode), path("all.dd.${readmode}.RDS"), emit: inferred
    path("dada2.denoised.pooled.${readmode}.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def bandsize = params.platform == 'pacbio' ? ', BAND_SIZE=32' : ''
    def dadaOpt = params.dada_opts ? "${params.dada_opts}" : "NA"
    def trimmode = readmode == "R1" ? "1" : "2"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(tidyverse))

    dadaOpt <- "${dadaOpt}"

    if (!is.na(dadaOpt)) {
      setDadaOpt(${dadaOpt})
      cat("dada Options:\\n",${dadaOpt},"\\n")
    }

    getN <- function(x) sum(getUniques(x))

    set.seed(100)

    cat("Processing all samples\\n")

    err <- readRDS("${err}")

    #Variable selection from CLI input flag --pool
    pool <- "${params.pool}"

    # 'pool' is a weird flag, either 'pseudo' (string), or T/F (bool)
    if(pool != "pseudo"){
      pool <- as.logical(pool)
    }
    
    # File parsing (these come from the process input channel)
    filts <- list.files('.', pattern="_${trimmode}.trim.fastq.gz")
    names(filts) <- gsub("_${trimmode}.trim.fastq.gz", "", filts)

    cat(paste0("Denoising ${readmode} reads: pool:", pool, "\\n"))

    dds <- dada(filts, 
      err=err, 
      multithread=${task.cpus}, 
      pool=pool ${bandsize})

    saveRDS(dds, "all.dd.${readmode}.RDS")

    tracking_dds <- as.data.frame(sapply(dds, getN))
    colnames(tracking_dds) <- c("dada2.denoised.pooled.${readmode}")
    tracking_dds <- tracking_dds %>%
        as_tibble() %>%
        mutate(SampleID = rownames(tracking_dds), .before = 1)
    write_csv(tracking_dds, "dada2.denoised.pooled.${readmode}.csv")
    """

    stub:
    def args = task.ext.args ?: ''
    """
    # add some real stuff here
    touch all.dd.${readmode}.RDS
    """
}
