process PER_SAMPLE_INFER {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(dereps)
    path(errs)
    path(fp, stageAs: "priors_R1")
    path(rp, stageAs: "priors_R2")
    val(stage)

    output:
    tuple val(meta), path("${meta.id}.dd.${stage}.R{1,2}.RDS"), emit: dds
    val(readmode), emit: readmode

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def dadaOpt = params.dada_opts ? "${params.dada_opts}" : "NA"
    readmode = errs.size() == 2 ? 'merged' : 'R1'
    run_fpriors = fp.size() == 0 ? "FALSE" : "TRUE"
    run_rpriors = fp.size() == 0 ? "FALSE" : "TRUE"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(Biostrings))
    suppressPackageStartupMessages(library(tidyverse))

    set.seed(100)

    getPriors <- function(x) {
      priors <- readDNAStringSet(x) |> as.vector() |> unname()
      return(priors)
    }

    dadaOpt <- "${dadaOpt}"

    if (!is.na(dadaOpt)) {
      setDadaOpt(${dadaOpt})
      cat("dada Options:\\n",${dadaOpt},"\\n")
    }

    cat("Processing:", "${meta.id}", "\\n")

    errF <- readRDS("errors.R1.RDS")
    derepF <- readRDS("${dereps[0]}")

    # TODO: there is probably a better way of doing this 
    # when using optparse
    paramsF <- list(
        derep=derepF, 
        err=errF,
        multithread=${task.cpus},
        pool=FALSE
    )

    if (as.logical("${run_fpriors}")) {
      paramsF\$priors <- getPriors("${fp}")
    }

    ddF <- do.call(dada, paramsF)
    saveRDS(ddF, "${meta.id}.dd.${stage}.R1.RDS")

    if (file.exists("errors.R2.RDS")) {
        errR <- readRDS("errors.R2.RDS")
        derepR <- readRDS("${dereps[1]}")
        paramsR <- list(
            derep=derepR, 
            err=errR, 
            multithread=${task.cpus}, 
            pool=FALSE
        )

        if (as.logical("${run_rpriors}")) {
            paramsR\$priors <- getPriors("${rp}")
        }

        message("DADA2 params, R2:", paramsR, "\\n")
        ddR <- do.call(dada, paramsR)
        saveRDS(ddR, "${meta.id}.dd.${stage}.R2.RDS")
    } else {
        # yes this is a little silly (it's the same as the dd.R1.RDS above).
        # But it does make the logical flow through this channel easier
        # TODO: check this line!!!
        saveRDS(ddF, paste("${meta.id}.${stage}.R1.RDS", sep="."))
    }
    """

    // stub:
    // def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // """
    // """
}
