process DADA2_LEARN_ERRORS {
    tag "${params.platform} ${params.learnerrors_function} ${readmode}"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), path(reads)

    output:
    tuple val(readmode), path("errors.${readmode}.RDS"), emit: error_models
    // tuple val(readmode), path("dereps.${readmode}.RDS"), emit: dereps_full
    path("${readmode}*.err.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    // Move platform-specific settings here?
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def derepreads = 100000
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages({
        library(dada2)
    })

    errFuncName <- "${params.learnerrors_function}"
    errFunc <- NA

    if (errFuncName == "custom") {
        source("${params.learnerrors_custom_code}")
        errFunc <- customErrfun
    } else if (errFuncName == "makeBinnedQualErrfun") {
        # TODO: add error checking on the bins
        errFunc <- makeBinnedQualErrfun(c(${params.learnerrors_quality_bins}))
    } else {
        # note lack of quotes
        errFunc <- ${params.learnerrors_function}
    }

    # At the moment we're only accepting additional R-based 
    # functional arguments as a string
    if (!nzchar("${params.dada_opts}")) {
        setDadaOpt(${params.dada_opts})
        cat("dada Options:\\n","${params.dada_opts}","\\n")
    }

    # File parsing
    filts <- list.files('.', pattern=paste0("${readmode}",".filtered.fastq.gz"), full.names = TRUE)

    set.seed(${params.random_seed})

    # Learn read error rates
    err <- learnErrors(filts, 
        multithread=${task.cpus},
        errorEstimationFunction=errFunc,
        verbose=TRUE,
        ${params.learnerrors_opts})

    # This is a rough correction for NovaSeq binning issues
    # See https://github.com/h3abionet/TADA/issues/31
    # Now deprecated in favor of using a standard error function

    if (as.logical("${params.quality_binning}") == TRUE ) {
        # TODO: this is likely to be deprecated 
        print("Running binning correction")
        errs <- t(apply(getErrors(err), 1, function(x) { x[x < x[40]] = x[40]; return(x)} ))
        err\$err_out <- errs
    }

    pdf(paste0("${readmode}.",errFuncName,".err.pdf"))
    plotErrors(err, nominalQ=TRUE)
    dev.off()

    saveRDS(err, paste0("errors.","${readmode}",".RDS")) 
    """
}
