// TODO: change to DADA2_PACBIO_LEARN_ERRORS
process PACBIO_DADA2_LEARN_ERRORS {
    tag "$readmode"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(readmode), path(reads)

    output:
    tuple val(readmode), path("errors.${readmode}.RDS"), emit: error_models
    path("${readmode}.err.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def derepreads = 100000
    // TODO: not even sure the below will work w/ nf-core style parameters, 
    // may need to go to a string or args-type modifications
    def dadaOpt = !params.dada_opts.isEmpty() ? "'${params.dada_opts.collect{k,v->"$k=$v"}.join(", ")}'" : 'NA'
    // TODO: will need to if-else this when implementing alternative error models
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    dadaOpt <- ${dadaOpt}

    if (!is.na(dadaOpt)) {
        setDadaOpt(dadaOpt)
        cat("dada Options:\n",dadaOpt,"\n")
    }
    
    # File parsing
    filts <- list.files('.', pattern="filtered.fastq.gz", full.names = TRUE)
    sample.namesF <- sapply(strsplit(basename(filts), "_"), `[`, 1) # Assumes filename = samplename_XXX.fastq.gz
    set.seed(100)

    dereps <- derepFastq(filts, n=${derepreads}, verbose=TRUE)

    # Learn forward error rates
    errs <- learnErrors(dereps, 
        nbases = 1e8, 
        errorEstimationFunction=PacBioErrfun, 
        BAND_SIZE=32, 
        multithread=${task.cpus},
        verbose=TRUE)

    pdf(paste0("${readmode}",".err.pdf"))
    plotErrors(errs, nominalQ=TRUE)
    dev.off()

    saveRDS(errs, paste0("errors.","${readmode}",".RDS"))
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    # TODO: make a proper stub
    """
}
